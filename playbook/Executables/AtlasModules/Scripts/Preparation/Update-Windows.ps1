# Runs on the destination PC before Atlas changes Windows. Provider-owned
# servicing is never killed; cancellation waits for the active operation.
[CmdletBinding()]
param([Parameter(Mandatory)][string]$JobPath, [switch]$FunctionsOnly, [switch]$VerifyOnly, [switch]$PersistentCancellation,
    [ValidateSet('preserve','automatic','manual')][string]$DriverMode = 'preserve')
$env:PSModulePath = [IO.Path]::Combine($PSHOME, 'Modules')
Set-StrictMode -Version 3.0
$ErrorActionPreference = 'Stop'
$ProgressPreference = 'SilentlyContinue'

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
        throw 'Windows and Store preparation must run as the signed-in session owner. Open Atlas in that account; SYSTEM setup and another administrator account are not supported.'
    }
}

function Get-PreparationNetworkProfile {
    $null = [Windows.Networking.Connectivity.NetworkInformation, Windows.Networking.Connectivity, ContentType=WindowsRuntime]
    return [Windows.Networking.Connectivity.NetworkInformation]::GetInternetConnectionProfile()
}

function Test-PreparationNetwork {
    $connectionProfile = Get-PreparationNetworkProfile
    if ($null -eq $connectionProfile -or [string]$connectionProfile.GetNetworkConnectivityLevel() -ne 'InternetAccess') { return $false }
    $cost = $connectionProfile.GetConnectionCost()
    return ([string]$cost.NetworkCostType -eq 'Unrestricted' -and -not $cost.Roaming -and -not $cost.OverDataLimit -and -not $cost.BackgroundDataUsageRestricted)
}

function Set-PreparationDriver {
    if ($DriverMode -eq 'preserve') { return }
    & (Join-Path $env:WINDIR 'System32\reg.exe') import (Join-Path $JobPath 'DriverPolicy.reg') | Add-Content -LiteralPath (Join-Path $JobPath 'updates.log')
    if ($LASTEXITCODE -ne 0) { throw 'Windows could not apply the selected driver policy.' }
}

function Test-PreparationRestart {
    foreach ($path in @('HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Component Based Servicing\RebootPending', 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\WindowsUpdate\Auto Update\RebootRequired')) {
        if (Test-Path -LiteralPath $path) { return $true }
    }
    $session = Get-ItemProperty -LiteralPath 'HKLM:\SYSTEM\CurrentControlSet\Control\Session Manager'
    $renames = $session.PSObject.Properties['PendingFileRenameOperations']
    if ($null -ne $renames) {
        if ($renames.Value -isnot [string[]]) { throw 'Windows pending file renames have an unexpected registry type.' }
        if (@($renames.Value | Where-Object { -not [string]::IsNullOrWhiteSpace($_) }).Count -gt 0) { return $true }
    }
    return [bool](New-Object -ComObject Microsoft.Update.SystemInfo).RebootRequired
}

function Test-PreparationUpdate($Update) {
    # Feature upgrades can leave the builds supported by the chosen playbook.
    # Optional previews are not a prerequisite for installing Atlas.
    if ($Update.BrowseOnly) { return $false }
    if ($DriverMode -eq 'manual' -and [int]$Update.Type -eq 2) { return $false }
    foreach ($category in $Update.Categories) {
        if ($category.CategoryID -eq '3689bdc8-b205-4af4-8d4a-a63924c5e9d5') { return $false }
    }
    return $true
}

function Get-PreparationStateSecurity {
    $security = New-Object Security.AccessControl.FileSecurity
    $security.SetSecurityDescriptorSddlForm('O:BAG:BAD:P(A;;FA;;;SY)(A;;FA;;;BA)(A;;0x1200a9;;;BU)')
    return $security
}

function Write-PreparationState([string]$Status, [string]$Stage, [int]$Completed = 0, [int]$Total = 0) {
    $os = Get-ItemProperty -LiteralPath 'HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion'
    $state = [ordered]@{
        schema = 1; status = $Status; stage = $Stage; completed = $Completed; total = $Total
        pid = $PID; processStart = [Diagnostics.Process]::GetCurrentProcess().StartTime.ToUniversalTime().ToFileTimeUtc()
        userSid = [Security.Principal.WindowsIdentity]::GetCurrent().User.Value
        build = [int]$os.CurrentBuildNumber; revision = [int]$os.UBR
        updatedAt = [DateTimeOffset]::UtcNow.ToUnixTimeSeconds()
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

function Invoke-PreparationWindows {
    for ($pass = 0; $pass -lt 8; $pass++) {
        Assert-PreparationContinue
        if (Test-PreparationRestart) { return 'reboot' }
        if (-not (Test-PreparationNetwork)) { throw (New-Object System.Net.NetworkInformation.NetworkInformationException) }
        Write-PreparationState running windows-search
        $session = New-Object -ComObject Microsoft.Update.Session
        $session.ClientApplicationID = 'Atlas preparation'
        $updates = New-Object -ComObject Microsoft.Update.UpdateColl
        foreach ($update in @(Find-PreparationWindowsUpdate $session)) {
            if ($update.InstallationBehavior.CanRequestUserInput) { throw "Windows requires interaction for: $($update.Title)" }
            if (-not $update.EulaAccepted) { $update.AcceptEula() }
            [void]$updates.Add($update)
        }
        if ($updates.Count -eq 0) { return 'complete' }
        Assert-PreparationContinue
        Write-PreparationState running windows-download 0 $updates.Count
        $downloader = $session.CreateUpdateDownloader()
        $downloader.Updates = $updates
        $downloaded = $downloader.Download()
        if ([int]$downloaded.ResultCode -ne 2) { throw "Windows update download failed: $($downloaded.ResultCode)" }
        Assert-PreparationContinue
        Write-PreparationState running windows-install 0 $updates.Count
        $installer = $session.CreateUpdateInstaller()
        $installer.Updates = $updates
        $installer.ForceQuiet = $true
        $installer.AllowSourcePrompts = $false
        $installed = $installer.Install()
        for ($index = 0; $index -lt $updates.Count; $index++) {
            $item = $installed.GetUpdateResult($index)
            "$($updates.Item($index).Title): result=$($item.ResultCode), HRESULT=$($item.HResult)" | Add-Content -LiteralPath (Join-Path $JobPath 'updates.log')
        }
        if ([int]$installed.ResultCode -ne 2) { throw "Windows could not install every update: $($installed.ResultCode). See updates.log." }
        if ($installed.RebootRequired -or (Test-PreparationRestart)) { return 'reboot' }
    }
    throw 'Windows still offers updates after eight passes. Resolve the remaining updates in Windows Settings.'
}

function Find-PreparationWindowsUpdate($Session) {
    $searcher = $Session.CreateUpdateSearcher()
    $searcher.Online = $true
    $found = $searcher.Search("IsInstalled=0 and IsHidden=0 and BrowseOnly=0 and DeploymentAction='Installation'")
    if ([int]$found.ResultCode -ne 2) { throw "Windows update search failed: $($found.ResultCode)" }
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
    if (-not $task.Wait(180000)) { throw 'Microsoft Store did not finish checking for updates.' }
    return $task.Result
}

function New-PreparationStoreManager {
    if (-not (Get-AppxPackage -Name Microsoft.WindowsStore)) { throw 'Microsoft Store is not registered for this user. Open Store once, then try again.' }
    Add-Type -AssemblyName System.Runtime.WindowsRuntime
    $null = [Windows.ApplicationModel.Store.Preview.InstallControl.AppInstallManager, Windows.ApplicationModel.Store.Preview.InstallControl, ContentType=WindowsRuntime]
    $null = [Windows.ApplicationModel.Store.Preview.InstallControl.AppInstallItem, Windows.ApplicationModel.Store.Preview.InstallControl, ContentType=WindowsRuntime]
    $null = [Windows.ApplicationModel.Store.Preview.InstallControl.AppUpdateOptions, Windows.ApplicationModel.Store.Preview.InstallControl, ContentType=WindowsRuntime]
    return New-Object Windows.ApplicationModel.Store.Preview.InstallControl.AppInstallManager
}

function Invoke-PreparationStore {
    for ($pass = 0; $pass -lt 8; $pass++) {
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
            foreach ($item in $items) {
                $status = $item.GetCurrentStatus()
                $state = [string]$status.InstallState
                if ($state -eq 'Completed') { $complete++; continue }
                # Store may return a queued download even when automatic
                # installation was requested. WinGet restarts this state too.
                if ($state -in @('ReadyToDownload','Paused') -and -not $restarted.ContainsKey($item.ProductId)) {
                    $manager.Restart($item.ProductId)
                    $restarted[$item.ProductId] = $true
                    continue
                }
                if ($state -in @('Error','Canceled','Paused','PausedLowBattery','PausedWiFiRecommended','PausedWiFiRequired')) {
                    throw "Microsoft Store needs attention: $($item.PackageFamilyName), $state, $($status.ErrorCode)"
                }
            }
            Write-PreparationState running store-install $complete $items.Count
            if ($complete -lt $items.Count) {
                if ([DateTime]::UtcNow -gt $deadline) { throw 'Store apps have not finished updating. Open Microsoft Store and resolve the remaining downloads.' }
                Start-Sleep -Seconds 2
            }
        } while ($complete -lt $items.Count)
        Assert-PreparationContinue
        # Store itself was included. A fresh manager/search observes any new
        # updates revealed by the newer Store version.
        $again = @(Wait-PreparationStoreSearch ($manager.SearchForAllUpdatesAsync('', 'Atlas', $options)))
        if (@($again | Where-Object { [string]$_.GetCurrentStatus().InstallState -ne 'Completed' }).Count -eq 0) { return }
    }
    throw 'Microsoft Store still offers updates after eight passes.'
}

function Assert-PreparationCurrent {
    Assert-PreparationContinue
    Assert-PreparationUser
    if (Test-PreparationRestart) { throw 'Restart Windows and run preparation again before installing Atlas.' }
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
    if (Test-PreparationRestart) { throw 'Restart Windows before installing Atlas.' }
    if (-not (Test-PreparationNetwork)) { throw 'The internet connection changed during preparation verification.' }
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
    if ((Invoke-PreparationWindows | Select-Object -Last 1) -eq 'reboot') {
        Write-PreparationState reboot windows-install
        exit 0
    }
    Invoke-PreparationStore
    Assert-PreparationContinue
    Write-PreparationState running verify
    if ((Invoke-PreparationWindows | Select-Object -Last 1) -eq 'reboot') {
        Write-PreparationState reboot windows-install
        exit 0
    }
    Write-PreparationState complete verify
}
catch [System.Net.NetworkInformation.NetworkInformationException] {
    Write-PreparationState network verify
}
catch [OperationCanceledException] {
    Write-PreparationState cancelled verify
}
catch {
    $_ | Out-String | Add-Content -LiteralPath (Join-Path $JobPath 'updates.log')
    Write-PreparationState failed verify
    exit 1
}
finally {
    if ($owned) { $mutex.ReleaseMutex() }
    if ($null -ne $mutex) { $mutex.Dispose() }
}
