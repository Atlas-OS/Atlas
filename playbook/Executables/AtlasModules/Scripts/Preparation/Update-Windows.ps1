# Brings Windows and Store apps up to date before Atlas changes Windows. Windows
# Update and Store work is never killed; cancellation waits for the active operation.
[CmdletBinding()]
param([Parameter(Mandatory)][string]$JobPath, [switch]$FunctionsOnly, [switch]$VerifyOnly,
    # Set by the app's protected job: 'cancel' always exists and stopping means it is
    # non-empty, and state.json gets the job's ACL.
    [switch]$PersistentCancellation,
    [ValidateSet('preserve','automatic','manual')][string]$DriverMode = 'preserve')
# This elevated worker must never autoload a module from an inherited user path.
$env:PSModulePath = [IO.Path]::Combine($PSHOME, 'Modules')
Set-StrictMode -Version 3.0
$ErrorActionPreference = 'Stop'
$ProgressPreference = 'SilentlyContinue'
$script:PreparationClock = [Diagnostics.Stopwatch]::StartNew()
$script:PreparationLastChange = 0L
$script:PreparationLastProgress = ''
# Restart markers seen by the last Test-PreparationRestart, so the app can name one
# that survives a restart instead of asking for another.
$script:PreparationRestartReasons = @()
# Why the last Test-PreparationNetwork refused the connection; the app words each cause.
$script:PreparationNetworkReason = $null
$script:PreparationStage = 'verify'
# Windows Update values: OperationResultCode 2 = succeeded, UpdateType 2 = driver.
$script:UpdateSucceeded = 2
$script:DriverUpdate = 2
# Searches per provider before giving up on one that keeps offering updates.
$script:PreparationPasses = 8

# A failure the app can explain. $Reason is a stable id the app words in the
# user's language; a nonzero $HResult is the provider's own error code.
function New-PreparationFailure([string]$Message, [string]$Reason, [int]$HResult) {
    $failure = [Exception]::new($Message)
    if ($Reason) { $failure.Data['reason'] = $Reason }
    if ($HResult -ne 0) { $failure.Data['errorCode'] = '0x{0:X8}' -f $HResult }
    return $failure
}

function New-PreparationStoreFailure([string]$PackageFamilyName, [string]$State, $ErrorCode) {
    $message = "Microsoft Store needs attention: $PackageFamilyName, $State"
    if ($null -ne $ErrorCode) { $message += ", $ErrorCode" }
    $reason = switch -Wildcard ($State) {
        'PausedLowBattery' { 'store-paused-battery' }
        'PausedWiFi*' { 'store-paused-network' }
    }
    $failure = New-PreparationFailure $message $reason $(if ($null -ne $ErrorCode) { $ErrorCode.HResult } else { 0 })
    $failure.Data['packageName'] = ($PackageFamilyName -split '_')[0].Split('.')[-1]
    return $failure
}

function Get-PreparationFailureDetail([Exception]$Exception) {
    $detail = @{ failureMessage = $Exception.Message }
    foreach ($key in @('packageName', 'errorCode', 'reason')) {
        if ($Exception.Data.Contains($key)) { $detail[$key] = [string]$Exception.Data[$key] }
    }
    if (-not $detail.ContainsKey('errorCode')) {
        # Report only a Windows or provider code. The CLR's own codes
        # (0x8013xxxx) and PowerShell's script errors name nothing to look up;
        # a wrapped .NET failure carries the real code on an inner exception.
        for ($cause = $Exception; $null -ne $cause; $cause = $cause.InnerException) {
            $code = if ($cause -is [ComponentModel.Win32Exception]) {
                if ($cause.NativeErrorCode) { 0x80070000 -bor ($cause.NativeErrorCode -band 0xFFFF) } else { 0 }
            } else { $cause.HResult }
            if ($code -eq 0 -or ($code -band 0xFFFF0000) -eq 0x80130000 -or
                $cause.GetType().Namespace -like 'System.Management.Automation*') { continue }
            $detail.errorCode = '0x{0:X8}' -f $code
            break
        }
    }
    return $detail
}

function Get-PreparationSessionOwner {
    if (-not ('AtlasPreparation.Session' -as [type])) {
        Add-Type -TypeDefinition @'
using System;
using System.ComponentModel;
using System.Runtime.InteropServices;
using System.Security.Principal;
namespace AtlasPreparation {
    public static class Session {
        [DllImport("wtsapi32.dll", CharSet=CharSet.Unicode, SetLastError=true)]
        static extern bool WTSQuerySessionInformation(IntPtr server, int session, int kind, out IntPtr buffer, out int bytes);
        [DllImport("wtsapi32.dll")] static extern void WTSFreeMemory(IntPtr buffer);
        static string Query(int session, int kind) {
            IntPtr buffer; int bytes;
            if (!WTSQuerySessionInformation(IntPtr.Zero, session, kind, out buffer, out bytes)) throw new Win32Exception();
            try { return Marshal.PtrToStringUni(buffer); } finally { WTSFreeMemory(buffer); }
        }
        public static string Owner(int session) {
            string user = Query(session, 5), domain = Query(session, 7);
            if (String.IsNullOrWhiteSpace(user)) throw new InvalidOperationException("The Windows session has no signed-in user.");
            return new NTAccount(domain, user).Translate(typeof(SecurityIdentifier)).Value;
        }
    }
}
'@
    }
    return [AtlasPreparation.Session]::Owner([Diagnostics.Process]::GetCurrentProcess().SessionId)
}

function Assert-PreparationUser(
    [string]$UserSid = [Security.Principal.WindowsIdentity]::GetCurrent().User.Value,
    [int]$SessionId = [Diagnostics.Process]::GetCurrentProcess().SessionId
) {
    if ($SessionId -lt 1 -or $UserSid -in @('S-1-5-18','S-1-5-19','S-1-5-20') -or
        (Get-PreparationSessionOwner) -cne $UserSid) {
        throw (New-PreparationFailure 'Windows and Store preparation must run as the signed-in session owner. Open Atlas in that account; SYSTEM setup and another administrator account are not supported.' 'session-owner')
    }
}

function Get-PreparationNetworkProfile {
    $null = [Windows.Networking.Connectivity.NetworkInformation, Windows.Networking.Connectivity, ContentType=WindowsRuntime]
    return [Windows.Networking.Connectivity.NetworkInformation]::GetInternetConnectionProfile()
}

function Test-PreparationNetwork {
    $script:PreparationNetworkReason = $null
    $connectionProfile = Get-PreparationNetworkProfile
    $level = if ($null -eq $connectionProfile) { 'None' } else { [string]$connectionProfile.GetNetworkConnectivityLevel() }
    if ($level -ne 'InternetAccess') {
        # LocalAccess and ConstrainedInternetAccess: connected, but Windows
        # has not confirmed internet access (a captive portal or filtering).
        $script:PreparationNetworkReason = if ($level -eq 'None') { 'offline' } else { 'limited' }
        return $false
    }
    $cost = $connectionProfile.GetConnectionCost()
    if ($cost.Roaming) {
        $script:PreparationNetworkReason = 'roaming'
        return $false
    }
    if ([string]$cost.NetworkCostType -ne 'Unrestricted' -or $cost.OverDataLimit -or $cost.BackgroundDataUsageRestricted) {
        $script:PreparationNetworkReason = 'metered'
        return $false
    }
    return $true
}

function Set-PreparationDriver {
    if ($DriverMode -eq 'preserve') { return }
    & (Join-Path $env:WINDIR 'System32\reg.exe') import (Join-Path $JobPath 'DriverPolicy.reg') | Add-Content -LiteralPath (Join-Path $JobPath 'updates.log')
    if ($LASTEXITCODE -ne 0) { throw 'Windows could not apply the selected driver policy.' }
}

function Test-PreparationRestart {
    $reasons = @()
    foreach ($marker in @(
            @{ Id = 'servicing'; Path = 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Component Based Servicing\RebootPending' },
            @{ Id = 'windows-update'; Path = 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\WindowsUpdate\Auto Update\RebootRequired' })) {
        if (Test-Path -LiteralPath $marker.Path) { $reasons += $marker.Id }
    }
    $session = Get-ItemProperty -LiteralPath 'HKLM:\SYSTEM\CurrentControlSet\Control\Session Manager'
    $renames = $session.PSObject.Properties['PendingFileRenameOperations']
    if ($null -ne $renames) {
        if ($renames.Value -isnot [string[]]) { throw 'Windows pending file renames have an unexpected registry type.' }
        if (@($renames.Value | Where-Object { -not [string]::IsNullOrWhiteSpace($_) }).Count -gt 0) { $reasons += 'file-renames' }
    }
    # Deferred file replacements are reported but do not call for a restart:
    # apps such as Xbox Gaming Services queue one at every boot. The update
    # provider is asked only when no blocking registry marker already answers.
    $blocking = @($reasons | Where-Object { $_ -ne 'file-renames' })
    if ($blocking.Count -eq 0 -and [bool](New-Object -ComObject Microsoft.Update.SystemInfo).RebootRequired) {
        $reasons += 'update-agent'
        $blocking += 'update-agent'
    }
    $script:PreparationRestartReasons = $reasons
    return $blocking.Count -gt 0
}

function Test-PreparationUpdate($Update) {
    # Feature upgrades can leave the builds supported by the chosen Atlas package.
    # Optional previews are not a prerequisite for installing Atlas.
    if ($Update.BrowseOnly) { return $false }
    if ($DriverMode -eq 'manual' -and [int]$Update.Type -eq $script:DriverUpdate) { return $false }
    foreach ($category in $Update.Categories) {
        # The 'Upgrades' category: feature updates.
        if ($category.CategoryID -eq '3689bdc8-b205-4af4-8d4a-a63924c5e9d5') { return $false }
    }
    return $true
}

# Must equal Get-AtlasRecoveryFileSecurity in app/resources/prepare/Stage-App.ps1;
# validate-preparation rejects any other ACL on state.json.
function Get-PreparationStateSecurity {
    $security = New-Object Security.AccessControl.FileSecurity
    $security.SetSecurityDescriptorSddlForm('O:BAG:BAD:P(A;;FA;;;SY)(A;;FA;;;BA)(A;;0x1200a9;;;BU)')
    return $security
}

function Write-PreparationState([string]$Status, [string]$Stage, [int]$Completed = 0, [int]$Total = 0, [hashtable]$Detail = @{}) {
    $script:PreparationStage = $Stage
    # A heartbeat is not evidence that the provider has made progress. Keep
    # separate clocks for elapsed time and the last actual progress change.
    $elapsed = [long]$script:PreparationClock.Elapsed.TotalSeconds
    $signature = "$Status/$Stage/$Completed/$Total/" + ($Detail | ConvertTo-Json -Compress)
    if ($signature -cne $script:PreparationLastProgress) {
        $script:PreparationLastProgress = $signature
        $script:PreparationLastChange = $elapsed
    }
    $activity = $Detail.Clone()
    $activity.elapsedSeconds = $elapsed
    $activity.unchangedSeconds = $elapsed - $script:PreparationLastChange
    $os = Get-ItemProperty -LiteralPath 'HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion'
    $state = [ordered]@{
        schema = 1; status = $Status; stage = $Stage; completed = $Completed; total = $Total
        pid = $PID; processStart = [Diagnostics.Process]::GetCurrentProcess().StartTime.ToUniversalTime().ToFileTimeUtc()
        userSid = [Security.Principal.WindowsIdentity]::GetCurrent().User.Value
        build = [int]$os.CurrentBuildNumber; revision = [int]$os.UBR
        updatedAt = [DateTimeOffset]::UtcNow.ToUnixTimeSeconds()
        activity = $activity
    }
    $json = $state | ConvertTo-Json -Compress
    $path = Join-Path $JobPath 'state.json'
    $temporary = Join-Path $JobPath 'state.tmp'
    $encoding = New-Object Text.UTF8Encoding($false)
    if ($PersistentCancellation) {
        $stream = New-Object IO.FileStream($temporary, [IO.FileMode]::CreateNew, [Security.AccessControl.FileSystemRights]::Write, [IO.FileShare]::None, 4096, [IO.FileOptions]::None, (Get-PreparationStateSecurity))
        try {
            $bytes = $encoding.GetBytes($json)
            $stream.Write($bytes, 0, $bytes.Length)
            $stream.Flush($true)
        } finally { $stream.Dispose() }
    }
    else {
        [IO.File]::WriteAllText($temporary, $json, $encoding)
    }
    if ([IO.File]::Exists($path)) { [IO.File]::Replace($temporary, $path, [NullString]::Value) }
    else { [IO.File]::Move($temporary, $path) }
    [Console]::WriteLine("ATLAS_PREP:$json")
}

function New-PreparationCallback {
    if (-not ('AtlasPreparation.Callback' -as [type])) {
        # WUA accepts an Automation callback with DISPID 0. Do not run
        # PowerShell on COM's callback threads (they have no runspace).
        # Progress is polled on our own thread through the job's GetProgress.
        Add-Type -TypeDefinition @'
using System.Runtime.InteropServices;
namespace AtlasPreparation {
    [ComVisible(true), ClassInterface(ClassInterfaceType.AutoDispatch)]
    public sealed class Callback {
        [DispId(0)] public void Invoke(object job, object args) { }
    }
}
'@
    }
    return New-Object AtlasPreparation.Callback
}

function Write-PreparationWindowsProgress($Job, $Updates, [string]$Stage) {
    $detail = @{}
    $completed = 0
    try {
        $progress = $Job.GetProgress()
        $detail.percent = [int]$progress.PercentComplete
        $index = [int]$progress.CurrentUpdateIndex
        if ($index -ge 0 -and $index -lt $Updates.Count) {
            $detail.currentUpdate = [string]$Updates.Item($index).Title
        }
        if ($Stage -eq 'windows-download') {
            $detail.bytesDownloaded = [long]$progress.TotalBytesDownloaded
            $detail.bytesTotal = [long]$progress.TotalBytesToDownload
        }
        for ($i = 0; $i -lt $Updates.Count; $i++) {
            try {
                if ([int]$progress.GetUpdateResult($i).ResultCode -eq $script:UpdateSucceeded) { $completed++ }
            } catch {
                Write-Verbose "Update $i has no result yet: $_"
            }
        }
    } catch {
        # A failed progress read must not abandon the operation or invent a
        # percentage; EndDownload and EndInstall own the result.
        $detail = @{}
        $completed = 0
    }
    Write-PreparationState running $Stage $completed $Updates.Count -Detail $detail
}

function Invoke-PreparationWindowsOperation($Provider, $Updates, [ValidateSet('Download','Install')][string]$Kind) {
    $callback = New-PreparationCallback
    $stage = if ($Kind -eq 'Download') { 'windows-download' } else { 'windows-install' }
    $job = if ($Kind -eq 'Download') { $Provider.BeginDownload($callback, $callback, $null) }
           else { $Provider.BeginInstall($callback, $callback, $null) }
    $ended = $false
    try {
        while (-not $job.IsCompleted) {
            Write-PreparationWindowsProgress $job $Updates $stage
            # Stop requests are honoured between operations, never by killing
            # servicing or abandoning the active job.
            Start-Sleep -Seconds 2
        }
        $ended = $true
        if ($Kind -eq 'Download') { return $Provider.EndDownload($job) }
        return $Provider.EndInstall($job)
    } finally {
        try {
            if (-not $ended) {
                # Even a failed journal write must not release the operation
                # lock while Windows is still servicing the machine.
                while (-not $job.IsCompleted) { Start-Sleep -Seconds 2 }
                if ($Kind -eq 'Download') { [void]$Provider.EndDownload($job) }
                else { [void]$Provider.EndInstall($job) }
            }
        } finally {
            $job.CleanUp()
            [GC]::KeepAlive($callback)
        }
    }
}

function Assert-PreparationContinue {
    $cancelPath = Join-Path $JobPath 'cancel'
    $cancelled = if ($PersistentCancellation) {
        # Metadata avoids a sharing violation while the user writes the marker
        # and never allocates memory based on a user-writable file's contents.
        $marker = [IO.FileInfo]::new($cancelPath)
        if (-not $marker.Exists) { throw 'The preparation cancellation marker is missing or unreadable.' }
        $marker.Length -gt 0
    } else { Test-Path -LiteralPath $cancelPath }
    if ($cancelled) {
        throw (New-Object OperationCanceledException 'Preparation stopped after the current operation.')
    }
}

# WUA installs an exclusive update (Impact 2) only on its own. The next pass
# searches again and offers whatever this one leaves out.
function Add-PreparationWindowsUpdate($Updates, $Update) {
    if ($Updates.Count -gt 0 -and
        ([int]$Update.InstallationBehavior.Impact -eq 2 -or [int]$Updates.Item(0).InstallationBehavior.Impact -eq 2)) { return }
    if (-not $Update.EulaAccepted) { $Update.AcceptEula() }
    [void]$Updates.Add($Update)
}

# Logs each update's result and returns the updates that did not succeed, with
# the provider's HRESULT and the revision-independent id a new search reuses.
function Get-PreparationFailedUpdate($Result, $Updates, [string]$Label) {
    for ($index = 0; $index -lt $Updates.Count; $index++) {
        $item = $Result.GetUpdateResult($index)
        $update = $Updates.Item($index)
        "$($update.Title): $Label=$($item.ResultCode), HRESULT=$($item.HResult)" | Add-Content -LiteralPath (Join-Path $JobPath 'updates.log')
        if ([int]$item.ResultCode -ne $script:UpdateSucceeded) {
            [pscustomobject]@{ Id = [string]$update.Identity.UpdateID; Update = $update; HResult = [int]$item.HResult }
        }
    }
}

# A failed update is offered again by the next search, so each one is retried
# once. A second failure, or one WUA does not attribute to an update, is
# reported with the provider's code.
function Register-PreparationRetry($Failed, $Result, [hashtable]$Retried, [string]$Message) {
    $repeated = @($Failed | Where-Object { $Retried.ContainsKey($_.Id) })
    if ($Failed.Count -eq 0 -or $repeated.Count -gt 0) {
        $code = [int]$Result.HResult
        foreach ($entry in @($repeated) + @($Failed)) {
            if ($entry.HResult -ne 0) { $code = $entry.HResult; break }
        }
        throw (New-PreparationFailure $Message -HResult $code)
    }
    foreach ($entry in $Failed) { $Retried[$entry.Id] = $true }
    "Retrying $($Failed.Count) failed update(s) after a fresh search." | Add-Content -LiteralPath (Join-Path $JobPath 'updates.log')
}

function Invoke-PreparationWindows {
    $retried = @{}
    for ($pass = 0; $pass -lt $script:PreparationPasses; $pass++) {
        Assert-PreparationContinue
        if (Test-PreparationRestart) { return 'reboot' }
        if (-not (Test-PreparationNetwork)) { throw (New-Object System.Net.NetworkInformation.NetworkInformationException) }
        Write-PreparationState running windows-search
        $session = New-Object -ComObject Microsoft.Update.Session
        $session.ClientApplicationID = 'Atlas preparation'
        $updates = New-Object -ComObject Microsoft.Update.UpdateColl
        $interactive = @()
        foreach ($update in @(Find-PreparationWindowsUpdate $session)) {
            if ($update.InstallationBehavior.CanRequestUserInput) {
                $interactive += $update
                continue
            }
            Add-PreparationWindowsUpdate $updates $update
        }
        if ($updates.Count -eq 0) {
            # CanRequestUserInput does not mean interaction is required. Finish
            # noninteractive work first, then try remaining updates with ForceQuiet.
            # Unsupported quiet handlers return a failure instead of a prompt.
            foreach ($update in $interactive) { Add-PreparationWindowsUpdate $updates $update }
            if ($updates.Count -eq 0) { return 'complete' }
        }
        Assert-PreparationContinue
        Write-PreparationState running windows-download 0 $updates.Count
        $downloader = $session.CreateUpdateDownloader()
        $downloader.Updates = $updates
        $downloaded = Invoke-PreparationWindowsOperation $downloader $updates Download
        if ([int]$downloaded.ResultCode -ne $script:UpdateSucceeded) {
            $failed = @(Get-PreparationFailedUpdate $downloaded $updates 'download result')
            Register-PreparationRetry $failed $downloaded $retried "Windows update download failed: $($downloaded.ResultCode). See updates.log."
            continue
        }
        Assert-PreparationContinue
        Write-PreparationState running windows-install 0 $updates.Count
        $installer = $session.CreateUpdateInstaller()
        $installer.Updates = $updates
        $installer.ForceQuiet = $true
        $installer.AllowSourcePrompts = $false
        if ($installer.RebootRequiredBeforeInstallation) {
            $script:PreparationRestartReasons = @('windows-update')
            return 'reboot'
        }
        $installed = Invoke-PreparationWindowsOperation $installer $updates Install
        $manual = @()
        $failed = @()
        foreach ($entry in @(Get-PreparationFailedUpdate $installed $updates 'result')) {
            if ($entry.Update.InstallationBehavior.CanRequestUserInput) { $manual += $entry.Update.Title }
            else { $failed += $entry }
        }
        if ($installed.RebootRequired) {
            $script:PreparationRestartReasons = @('windows-update')
            return 'reboot'
        }
        if (Test-PreparationRestart) { return 'reboot' }
        if ($manual.Count -gt 0) { throw (New-PreparationFailure "Windows could not finish these updates automatically. Finish them in Windows Settings, then retry: $($manual -join '; ')" 'manual-updates') }
        if ([int]$installed.ResultCode -ne $script:UpdateSucceeded) {
            Register-PreparationRetry $failed $installed $retried "Windows could not install every update: $($installed.ResultCode). See updates.log."
        }
    }
    throw (New-PreparationFailure "Windows still offers updates after $script:PreparationPasses passes. Resolve the remaining updates in Windows Settings." 'windows-passes')
}

function Find-PreparationWindowsUpdate($Session) {
    $searcher = $Session.CreateUpdateSearcher()
    $searcher.Online = $true
    $callback = New-PreparationCallback
    $job = $searcher.BeginSearch("IsInstalled=0 and IsHidden=0 and BrowseOnly=0 and DeploymentAction='Installation'", $callback, $null)
    try {
        while (-not $job.IsCompleted) {
            Write-PreparationState running windows-search
            Start-Sleep -Seconds 2
        }
        $found = $searcher.EndSearch($job)
    } finally {
        $job.CleanUp()
        [GC]::KeepAlive($callback)
    }
    if ([int]$found.ResultCode -ne $script:UpdateSucceeded) { throw "Windows update search failed: $($found.ResultCode)" }
    foreach ($update in $found.Updates) {
        if (Test-PreparationUpdate $update) { $update }
    }
}

function Wait-PreparationStoreSearch($Operation) {
    $resultType = [System.Collections.Generic.IReadOnlyList[Windows.ApplicationModel.Store.Preview.InstallControl.AppInstallItem]]
    $asTask = [System.WindowsRuntimeSystemExtensions].GetMethods() | Where-Object {
        $_.Name -eq 'AsTask' -and $_.IsGenericMethod -and $_.GetGenericArguments().Count -eq 1 -and $_.GetParameters().Count -eq 1
    } | Select-Object -First 1
    $task = $asTask.MakeGenericMethod($resultType).Invoke($null, @($Operation))
    $deadline = [DateTime]::UtcNow.AddMinutes(3)
    while (-not $task.Wait(2000)) {
        Write-PreparationState running store-search
        if ([DateTime]::UtcNow -gt $deadline) { throw 'Microsoft Store did not finish checking for updates.' }
    }
    return $task.Result
}

function New-PreparationStoreManager {
    if (-not (Get-AppxPackage -Name Microsoft.WindowsStore)) { throw (New-PreparationFailure 'Microsoft Store is not registered for this user. Open Store once, then try again.' 'store-missing') }
    Add-Type -AssemblyName System.Runtime.WindowsRuntime
    $null = [Windows.ApplicationModel.Store.Preview.InstallControl.AppInstallManager, Windows.ApplicationModel.Store.Preview.InstallControl, ContentType=WindowsRuntime]
    $null = [Windows.ApplicationModel.Store.Preview.InstallControl.AppInstallItem, Windows.ApplicationModel.Store.Preview.InstallControl, ContentType=WindowsRuntime]
    $null = [Windows.ApplicationModel.Store.Preview.InstallControl.AppUpdateOptions, Windows.ApplicationModel.Store.Preview.InstallControl, ContentType=WindowsRuntime]
    return New-Object Windows.ApplicationModel.Store.Preview.InstallControl.AppInstallManager
}

function Invoke-PreparationStore {
    for ($pass = 0; $pass -lt $script:PreparationPasses; $pass++) {
        Assert-PreparationContinue
        if (-not (Test-PreparationNetwork)) { throw (New-Object System.Net.NetworkInformation.NetworkInformationException) }
        Write-PreparationState running store-search
        $manager = New-PreparationStoreManager
        # A retry must remove failed queue records before a fresh search.
        # This is the same queue recovery used by WinGet's Store installer.
        foreach ($previous in @($manager.AppInstallItems)) {
            if ([string]$previous.GetCurrentStatus().InstallState -in @('Error','Canceled')) {
                $product = $previous.ProductId
                $manager.Cancel($product)
                $removed = $false
                for ($wait = 0; $wait -lt 50; $wait++) {
                    Assert-PreparationContinue
                    if (@($manager.AppInstallItems | Where-Object ProductId -eq $product).Count -eq 0) { $removed = $true; break }
                    Start-Sleep -Milliseconds 200
                }
                if (-not $removed) { throw "Microsoft Store could not clear the failed update: $product" }
            }
        }
        $options = New-Object Windows.ApplicationModel.Store.Preview.InstallControl.AppUpdateOptions
        $options.AllowForcedAppRestart = $true
        $options.AutomaticallyDownloadAndInstallUpdateIfFound = $true
        $operation = $manager.SearchForAllUpdatesAsync('', 'Atlas', $options)
        $items = @(Wait-PreparationStoreSearch $operation)
        # Include already active Store work so an empty new search cannot be
        # mistaken for completion while another download is still in progress.
        $items = @(@($items) + @($manager.AppInstallItems) | Group-Object PackageFamilyName | ForEach-Object { $_.Group[0] })
        if ($items.Count -eq 0) { return }
        $deadline = [DateTime]::UtcNow.AddMinutes(30)
        $restarted = @{}
        do {
            $complete = 0
            $percent = 0.0
            foreach ($item in $items) {
                $status = $item.GetCurrentStatus()
                $state = [string]$status.InstallState
                if ($state -eq 'Completed') { $complete++; $percent += 100; continue }
                $percent += [Math]::Max(0, [Math]::Min(100, [double]$status.PercentComplete))
                # Store may return a queued download even when automatic
                # installation was requested. WinGet restarts this state too.
                if ($state -in @('ReadyToDownload','Paused') -and -not $restarted.ContainsKey($item.ProductId)) {
                    $manager.Restart($item.ProductId)
                    $restarted[$item.ProductId] = $true
                    continue
                }
                if ($state -in @('Error','Canceled','Paused','PausedLowBattery','PausedWiFiRecommended','PausedWiFiRequired')) {
                    throw (New-PreparationStoreFailure $item.PackageFamilyName $state $status.ErrorCode)
                }
            }
            Write-PreparationState running store-install $complete $items.Count -Detail @{percent = [int][Math]::Floor($percent / $items.Count)}
            if ($complete -lt $items.Count) {
                if ([DateTime]::UtcNow -gt $deadline) { throw (New-PreparationFailure 'Store apps have not finished updating. Open Microsoft Store and resolve the remaining downloads.' 'store-timeout') }
                Start-Sleep -Seconds 2
            }
        } while ($complete -lt $items.Count)
        Assert-PreparationContinue
        # Updating Store itself can reveal more updates; search again before finishing.
        $again = @(Wait-PreparationStoreSearch ($manager.SearchForAllUpdatesAsync('', 'Atlas', $options)))
        if (@($again | Where-Object { [string]$_.GetCurrentStatus().InstallState -ne 'Completed' }).Count -eq 0) { return }
    }
    throw (New-PreparationFailure "Microsoft Store still offers updates after $script:PreparationPasses passes." 'store-passes')
}

function Assert-PreparationCurrent {
    Assert-PreparationContinue
    Assert-PreparationUser
    if (Test-PreparationRestart) { throw "Restart Windows and run preparation again before installing Atlas (pending: $($script:PreparationRestartReasons -join ', '))." }
    if (-not (Test-PreparationNetwork)) { throw 'Connect to unrestricted internet before verifying Windows and Store updates.' }
    Write-PreparationState running windows-search
    $session = New-Object -ComObject Microsoft.Update.Session
    $session.ClientApplicationID = 'Atlas preparation verification'
    if (@(Find-PreparationWindowsUpdate $session).Count -gt 0) { throw 'Windows still offers required updates. Finish preparation in Atlas, then retry installation.' }
    Assert-PreparationContinue
    Write-PreparationState running store-search
    $manager = New-PreparationStoreManager
    $options = New-Object Windows.ApplicationModel.Store.Preview.InstallControl.AppUpdateOptions
    $options.AllowForcedAppRestart = $false
    # This API queues found updates paused even when downloads are disabled.
    # Do not cancel another client's queue; the normal preparation pass resumes it.
    $options.AutomaticallyDownloadAndInstallUpdateIfFound = $false
    $found = @(Wait-PreparationStoreSearch ($manager.SearchForAllUpdatesAsync('', 'Atlas', $options)))
    $pending = @(@($found) + @($manager.AppInstallItems) | Where-Object { [string]$_.GetCurrentStatus().InstallState -ne 'Completed' })
    if ($pending.Count -gt 0) { throw 'Microsoft Store apps still need updates. Finish the queued updates in Atlas or Microsoft Store, then retry installation.' }
    Assert-PreparationContinue
    if (@(Find-PreparationWindowsUpdate $session).Count -gt 0) { throw 'Windows offered additional updates during verification. Finish preparation, then retry.' }
    if (Test-PreparationRestart) { throw "Restart Windows before installing Atlas (pending: $($script:PreparationRestartReasons -join ', '))." }
    if (-not (Test-PreparationNetwork)) { throw 'The internet connection changed during preparation verification.' }
}

function Invoke-PreparationStoreWithRetry {
    # Retry only 0x80240016 (another install is in progress), never an app-in-use
    # or unknown error.
    for ($attempt = 0; $attempt -lt 4; $attempt++) {
        try { Invoke-PreparationStore; return }
        catch {
            $detail = Get-PreparationFailureDetail $_.Exception
            if (-not $detail.ContainsKey('errorCode') -or $detail.errorCode -ne '0x80240016' -or $attempt -eq 3 -or (Test-PreparationRestart)) { throw }
            "Store is busy; retrying in 15 seconds (attempt $($attempt + 2) of 4)." |
                Add-Content -LiteralPath (Join-Path $JobPath 'updates.log')
            for ($second = 0; $second -lt 15; $second++) {
                Assert-PreparationContinue
                Write-PreparationState running store-search
                Start-Sleep -Seconds 1
            }
        }
    }
}

function Invoke-PreparationUpdates {
    try {
        # The last value only: stray pipeline output must not become the status.
        if ((Invoke-PreparationWindows | Select-Object -Last 1) -eq 'reboot') { return 'reboot' }
        Invoke-PreparationStoreWithRetry
        Assert-PreparationContinue
        Write-PreparationState running verify
        return (Invoke-PreparationWindows | Select-Object -Last 1)
    }
    catch {
        # A failed or interrupted provider can still have committed updates.
        # Keep the original diagnostic even when restarting is the next action.
        $_ | Out-String | Add-Content -LiteralPath (Join-Path $JobPath 'updates.log')
        try {
            if (Test-PreparationRestart) { return 'reboot' }
        } catch {
            $_ | Out-String | Add-Content -LiteralPath (Join-Path $JobPath 'updates.log')
        }
        throw
    }
}

if ($FunctionsOnly) { return }
$mutex = $null
$owned = $false
try {
    [Console]::OutputEncoding = New-Object Text.UTF8Encoding($false)
    $principal = New-Object Security.Principal.WindowsPrincipal([Security.Principal.WindowsIdentity]::GetCurrent())
    if (-not $principal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) { throw 'Administrator access is required.' }
    Assert-PreparationUser
    $mutex = New-Object Threading.Mutex($false, 'Global\AtlasOS.WindowsPreparation')
    try { $owned = $mutex.WaitOne(0) } catch [Threading.AbandonedMutexException] { $owned = $true }
    if (-not $owned) { throw 'Another Atlas preparation is running.' }
    Write-PreparationState running verify
    if ($VerifyOnly) {
        # Keep the existing Atlas manual-driver policy without importing or
        # changing it. Software updates remain mandatory in either mode.
        $driverPolicy = Get-ItemProperty -LiteralPath 'HKLM:\SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate' -Name ExcludeWUDriversInQualityUpdate -ErrorAction SilentlyContinue
        if ($driverPolicy -and $driverPolicy.ExcludeWUDriversInQualityUpdate -eq 1) { $DriverMode = 'manual' }
        Assert-PreparationCurrent
        Write-PreparationState complete verify
        exit 0
    }
    Set-PreparationDriver
    if ((Invoke-PreparationUpdates | Select-Object -Last 1) -eq 'reboot') {
        Write-PreparationState reboot windows-install -Detail @{ restartReasons = @($script:PreparationRestartReasons) }
        exit 0
    }
    Write-PreparationState complete verify
}
catch [System.Net.NetworkInformation.NetworkInformationException] {
    Write-PreparationState network verify -Detail @{ networkReason = $script:PreparationNetworkReason }
}
catch [OperationCanceledException] {
    Write-PreparationState cancelled verify
}
catch {
    $failureDetail = Get-PreparationFailureDetail $_.Exception
    $_ | Out-String | Add-Content -LiteralPath (Join-Path $JobPath 'updates.log')
    Write-PreparationState failed $script:PreparationStage -Detail $failureDetail
    exit 1
}
finally {
    if ($owned) { $mutex.ReleaseMutex() }
    if ($null -ne $mutex) { $mutex.Dispose() }
}
