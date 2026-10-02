# Brings Windows and Store apps up to date before Atlas changes Windows. Windows
# Update and Store work is never killed; cancellation waits for the active operation.
[CmdletBinding()]
param([Parameter(Mandatory)][string]$JobPath, [switch]$FunctionsOnly, [switch]$VerifyOnly,
    # Set by the app's protected job: 'cancel' always exists and stopping means it is
    # non-empty, and state.json gets the job's ACL.
    [switch]$PersistentCancellation,
    [ValidateSet('preserve','automatic','manual')][string]$DriverMode = 'preserve',
    # Moving Windows to another release (see WindowsTransition.ps1). Lists are
    # comma-separated, as -File passes every argument as one string.
    [ValidatePattern('^\d{2}H\d$')][string]$WindowsTarget,
    [int]$TargetBuild,
    [ValidatePattern('^\d{5}(,\d{5})*$')][string]$SourceBuilds,
    # KB numbers the target's feature update and its optional prerequisite are known
    # under. They name what the log shows; the offer itself is chosen by its release.
    [ValidatePattern('^\d{7}(,\d{7})*$')][string]$FeatureKb,
    [ValidatePattern('^\d{7}(,\d{7})*$')][string]$PrerequisiteKb,
    # The revision the feature update needs; it only picks the reason for no offer.
    [int]$MinimumRevision,
    # The user accepted the licence terms of the target release.
    [switch]$AcceptLicense,
    # Turn Windows Update on for this run if it is off, paused or delayed.
    [switch]$OpenWindowsUpdate,
    [switch]$CommitFeatureUpdate,
    # Only look for the target's offer again: once the target is set, the
    # monthly updates are done, so a recheck while waiting for Windows Update
    # skips them and the long in-run wait.
    [switch]$OfferOnly,
    [switch]$RestoreWindowsUpdate)
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
# What the worker's reports say while it searches: set while it waits for
# Windows Update to offer a new release, so the app words the wait as one.
$script:PreparationSearchDetail = @{}
# Updates that installed and were offered again, by the registry value below.
$script:PreparationReofferedRoot = 'SOFTWARE\AtlasOS\Preparation'

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
    foreach ($key in @('packageName', 'errorCode', 'reason', 'setting', 'drive', 'freeGb', 'neededGb', 'hardware')) {
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
    try { Import-AtlasRegistryFile (Join-Path $JobPath 'DriverPolicy.reg') (Join-Path $JobPath 'updates.log') }
    catch { throw "Windows could not apply the selected driver policy: $($_.Exception.Message)" }
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
    # A commit or put-back names itself, so a Get ready run never follows it.
    if ($CommitFeatureUpdate) { $state.operation = 'commit' }
    elseif ($RestoreWindowsUpdate) { $state.operation = 'restore' }
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

# An update by its id and revision: a new revision is a new update to install.
function Get-PreparationUpdateKey($Update) {
    $identity = $Update.Identity
    $revision = if ($null -ne $identity.PSObject.Properties['RevisionNumber']) { [int]$identity.RevisionNumber } else { 0 }
    return "$([string]$identity.UpdateID)/$revision"
}

# Some updates install successfully and are offered again straight away: the
# Windows Security platform update can stay offered while the app keeps its old
# version. Installing it again changes nothing, so such an update is recorded
# under HKLM, which only administrators write, and is no longer waited for; the
# install's own check reads the same record.
function Read-PreparationReoffered {
    $value = Get-AtlasTransitionValue $script:PreparationReofferedRoot 'Reoffered'
    if (-not $value.Present -or $value.Kind -ne 'String') { return @() }
    # Assigned before @(): Windows PowerShell passes a parsed JSON array down the
    # pipeline as one object.
    try { $parsed = [string]$value.Data | ConvertFrom-Json -ErrorAction Stop }
    catch { return @() }
    $entries = @($parsed)
    $cutoff = [DateTime]::UtcNow.AddDays(-30)
    foreach ($entry in $entries) {
        if ($null -eq $entry -or $null -eq $entry.PSObject.Properties['key'] -or $null -eq $entry.PSObject.Properties['at']) { continue }
        $at = [DateTime]::MinValue
        if (-not [DateTime]::TryParse([string]$entry.at, [Globalization.CultureInfo]::InvariantCulture,
                [Globalization.DateTimeStyles]::AdjustToUniversal, [ref]$at) -or $at -lt $cutoff) { continue }
        if ([string]$entry.key -notmatch '^[^\x00-\x1f]{1,80}$') { continue }
        $entry
    }
}

function Write-PreparationReoffered($Entries) {
    $json = ConvertTo-Json -InputObject @($Entries) -Depth 3 -Compress
    Set-AtlasTransitionValue $script:PreparationReofferedRoot 'Reoffered' 'String' $json
}

function Get-PreparationReofferedKey {
    $keys = New-Object 'Collections.Generic.HashSet[string]'
    foreach ($entry in @(Read-PreparationReoffered)) { [void]$keys.Add([string]$entry.key) }
    return , $keys
}

# What the PC has of an update that keeps being offered, where Windows says.
function Get-PreparationInstalledVersion($Update) {
    $kbs = @(Get-PreparationUpdateKb $Update)
    try {
        if ($kbs -contains '5007651') {
            $app = @(Get-AppxPackage -AllUsers -Name 'Microsoft.SecHealthUI' -ErrorAction Stop | Sort-Object { [version]$_.Version } -Descending)
            if ($app.Count -gt 0) { return "Microsoft.SecHealthUI $($app[0].Version)" }
        }
        if ($kbs -contains '4052623') { return "Defender platform $((Get-MpComputerStatus -ErrorAction Stop).AMProductVersion)" }
    }
    catch { return "unreadable ($($_.Exception.Message))" }
    return ''
}

function Add-PreparationReoffered($Update) {
    $title = [string]$Update.Title
    $offered = if ($title -match '\(Version ([0-9.]+)\)') { $Matches[1] } else { '' }
    $installed = Get-PreparationInstalledVersion $Update
    $line = "reoffered-after-success, not installed again: '$title' KB=$((@(Get-PreparationUpdateKb $Update)) -join ',') offered=$offered installed=$installed"
    $line | Add-Content -LiteralPath (Join-Path $JobPath 'updates.log')
    Write-AtlasTransitionEvidence $line
    try {
        $key = Get-PreparationUpdateKey $Update
        $entries = @(Read-PreparationReoffered | Where-Object { [string]$_.key -ne $key })
        $entries += [pscustomobject][ordered]@{ key = $key; kb = (@(Get-PreparationUpdateKb $Update) -join ','); title = $title.Substring(0, [Math]::Min($title.Length, 200)); at = [DateTime]::UtcNow.ToString('o') }
        if ($entries.Count -gt 20) { $entries = $entries[($entries.Count - 20)..($entries.Count - 1)] }
        Write-PreparationReoffered $entries
    }
    catch { "The re-offered update could not be recorded: $($_.Exception.Message)" | Add-Content -LiteralPath (Join-Path $JobPath 'updates.log') }
}

# The revision of this build an update's title names, as in "(26200.9550)", or 0.
function Get-PreparationTitleRevision($Update, [int]$Build) {
    $property = $Update.PSObject.Properties['Title']
    $title = if ($null -ne $property) { [string]$property.Value } else { '' }
    $revision = 0
    foreach ($match in [regex]::Matches($title, "(^|[^0-9])$Build\.(\d{1,6})([^0-9]|$)")) {
        $revision = [Math]::Max($revision, [int]$match.Groups[2].Value)
    }
    return $revision
}

# Leaves out what a newer update in the same pass replaces: a cumulative update
# for this build below the newest one offered, or one another update lists as
# superseded. Installing both installs the older only to replace it, and its
# restart can leave the newer one to install again.
function Select-PreparationNewestUpdate($Updates) {
    $all = @($Updates)
    if ($all.Count -lt 2) { return $all }
    $build = (Get-PreparationWindowsVersion).Build
    $newest = 0
    foreach ($update in $all) { $newest = [Math]::Max($newest, (Get-PreparationTitleRevision $update $build)) }
    $superseded = @{}
    foreach ($update in $all) {
        $property = $update.PSObject.Properties['SupersededUpdateIDs']
        if ($null -eq $property -or $null -eq $property.Value) { continue }
        foreach ($id in @($property.Value)) { $superseded[[string]$id] = $true }
    }
    foreach ($update in $all) {
        $revision = Get-PreparationTitleRevision $update $build
        $id = [string]$update.Identity.UpdateID
        if (($revision -gt 0 -and $revision -lt $newest) -or $superseded.ContainsKey($id)) {
            $line = "Left '$($update.Title)' for now: a newer update in this pass replaces it."
            $line | Add-Content -LiteralPath (Join-Path $JobPath 'updates.log')
            Write-AtlasTransitionEvidence $line
            continue
        }
        $update
    }
}

function Invoke-PreparationWindows {
    $retried = @{}
    # Updates this run installed successfully, by id and revision.
    $succeeded = @{}
    for ($pass = 0; $pass -lt $script:PreparationPasses; $pass++) {
        Assert-PreparationContinue
        if (Test-PreparationRestart) { return 'reboot' }
        if (-not (Test-PreparationNetwork)) { throw (New-Object System.Net.NetworkInformation.NetworkInformationException) }
        Write-PreparationState running windows-search
        $session = New-Object -ComObject Microsoft.Update.Session
        $session.ClientApplicationID = 'Atlas preparation'
        $updates = New-Object -ComObject Microsoft.Update.UpdateColl
        $interactive = @()
        foreach ($update in @(Select-PreparationNewestUpdate (@(Find-PreparationWindowsUpdate $session) + @(Find-PreparationPrerequisiteUpdate $session)))) {
            if ($succeeded.ContainsKey((Get-PreparationUpdateKey $update))) {
                Add-PreparationReoffered $update
                continue
            }
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
        for ($index = 0; $index -lt $updates.Count; $index++) {
            if ([int]$installed.GetUpdateResult($index).ResultCode -eq $script:UpdateSucceeded) {
                $succeeded[(Get-PreparationUpdateKey $updates.Item($index))] = $true
            }
        }
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

# Which update service the searches ask. The default (ssDefault, 0) is the first
# service registered with Automatic Updates that isn't a managed server, which on
# some PCs is another catalog, such as a flighting one, that doesn't offer the
# Windows release. ssWindowsUpdate (2) asks the Windows Update service itself:
# https://learn.microsoft.com/windows/win32/api/wuapicommon/ne-wuapicommon-serverselection
# A PC whose updates come from its organisation's server (AU\UseWUServer=1) keeps
# the default, so they still come from there: a move refuses such a PC before it
# searches. Downloads and installs follow the updates a search returned, so they
# use the same service.
function Get-PreparationServerSelection {
    $server = Get-AtlasTransitionValue 'SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate\AU' 'UseWUServer'
    if ($server.Present -and $server.Kind -eq 'DWord' -and [int64]$server.Data -eq 1) { return 0 }
    return 2
}

# One searcher as every search sets it up: online, on the service above.
function New-PreparationSearcher($Session) {
    $searcher = $Session.CreateUpdateSearcher()
    $searcher.Online = $true
    $searcher.ServerSelection = Get-PreparationServerSelection
    return $searcher
}

# The service a searcher asks, for the log. Its ServiceID means something only
# with ssOthers (3); otherwise it reads as zeros.
function Format-PreparationService($Searcher) {
    $selection = [int]$Searcher.ServerSelection
    switch ($selection) {
        0 { 'ServerSelection=0 (the default service)' }
        1 { 'ServerSelection=1 (the managed server)' }
        2 { 'ServerSelection=2 (Windows Update)' }
        default { "ServerSelection=$selection (service $($Searcher.ServiceID))" }
    }
}

function Invoke-PreparationSearch($Session, [string]$Criteria, [switch]$IncludeSuperseded) {
    $searcher = New-PreparationSearcher $Session
    # A hidden update can be superseded by another hidden one; without this the
    # search for hidden updates can miss it.
    if ($IncludeSuperseded) { $searcher.IncludePotentiallySupersededUpdates = $true }
    $callback = New-PreparationCallback
    $job = $searcher.BeginSearch($Criteria, $callback, $null)
    try {
        while (-not $job.IsCompleted) {
            Write-PreparationState running windows-search -Detail $script:PreparationSearchDetail
            Start-Sleep -Seconds 2
        }
        $found = $searcher.EndSearch($job)
    } finally {
        $job.CleanUp()
        [GC]::KeepAlive($callback)
    }
    Write-AtlasTransitionEvidence "search on $(Format-PreparationService $searcher): result $($found.ResultCode), $(@($found.Updates).Count) update(s) for $Criteria"
    if ([int]$found.ResultCode -ne $script:UpdateSucceeded) { throw "Windows update search failed: $($found.ResultCode)" }
    foreach ($update in $found.Updates) { $update }
}

function Find-PreparationWindowsUpdate($Session) {
    $handled = Get-PreparationReofferedKey
    foreach ($update in @(Invoke-PreparationSearch $Session "IsInstalled=0 and IsHidden=0 and BrowseOnly=0 and DeploymentAction='Installation'")) {
        if (-not (Test-PreparationUpdate $update)) { continue }
        if ($handled.Contains((Get-PreparationUpdateKey $update))) {
            "Left '$($update.Title)': it installed before and Windows offers it again." | Add-Content -LiteralPath (Join-Path $JobPath 'updates.log')
            continue
        }
        $update
    }
}

# WU_E_INVALID_CRITERIA: this Windows Update client does not know a criterion.
$script:InvalidCriteria = -2145124302

# The provider's HRESULT, which PowerShell wraps in its own exceptions.
function Get-PreparationHResult([Exception]$Exception) {
    for ($cause = $Exception; $null -ne $cause; $cause = $cause.InnerException) {
        if ($cause -is [Runtime.InteropServices.COMException] -or ($cause.HResult -ne 0 -and ($cause.HResult -band 0xFFFF0000) -ne 0x80130000)) {
            return $cause.HResult
        }
    }
    return 0
}

function Get-PreparationUpdateKb($Update) {
    $property = $Update.PSObject.Properties['KBArticleIDs']
    if ($null -eq $property -or $null -eq $property.Value) { return }
    foreach ($kb in $property.Value) { [string]$kb }
}

function Test-PreparationUpgradeCategory($Update) {
    foreach ($category in @($Update.Categories)) {
        if ([string]$category.CategoryID -eq '3689bdc8-b205-4af4-8d4a-a63924c5e9d5') { return $true }
    }
    return $false
}

# One line per offer, so a log shows exactly what Windows Update offered.
function Format-PreparationOffer($Update) {
    $read = { param($Name) $property = $Update.PSObject.Properties[$Name]; if ($null -ne $property) { $property.Value } }
    $categories = @(foreach ($category in @(& $read 'Categories')) { [string]$category.Name }) -join '/'
    $behaviour = & $read 'InstallationBehavior'
    $reboot = if ($null -ne $behaviour -and $null -ne $behaviour.PSObject.Properties['RebootBehavior']) { $behaviour.RebootBehavior } else { '' }
    $identity = & $read 'Identity'
    $id = if ($null -ne $identity) { "$($identity.UpdateID) rev $(if ($null -ne $identity.PSObject.Properties['RevisionNumber']) { $identity.RevisionNumber })" } else { '' }
    return "'$(& $read 'Title')' KB=$((@(Get-PreparationUpdateKb $Update)) -join ',') id=$id categories=$categories browseOnly=$(& $read 'BrowseOnly') mandatory=$(& $read 'IsMandatory') eula=$(& $read 'EulaAccepted') deployment=$(& $read 'DeploymentAction') reboot=$reboot size=$(& $read 'MaxDownloadSize')"
}

# Whether an update's title names the target release, as in "Windows 11, version
# 26H2". Release names are not translated, so this holds in every language.
function Test-PreparationTargetTitle($Update, [string]$Release = $WindowsTarget) {
    if (-not $Release) { return $false }
    $property = $Update.PSObject.Properties['Title']
    $title = if ($null -ne $property) { [string]$property.Value } else { '' }
    return $title -match "(^|[^0-9A-Za-z])$([regex]::Escape($Release))([^0-9A-Za-z]|$)"
}

function Test-PreparationKnownKb($Update, [string]$List) {
    if (-not $List) { return $false }
    $known = @($List -split ',')
    return @(Get-PreparationUpdateKb $Update | Where-Object { $known -contains $_ }).Count -gt 0
}

# A Windows cumulative update for this build: its title names the build and a
# revision above the one installed, as in "(KB5124010) (26200.9600)".
function Test-PreparationNewerRevision($Update, $Version) {
    $property = $Update.PSObject.Properties['Title']
    $title = if ($null -ne $property) { [string]$property.Value } else { '' }
    foreach ($match in [regex]::Matches($title, "(^|[^0-9])$($Version.Build)\.(\d{1,6})([^0-9]|$)")) {
        if ([int]$match.Groups[2].Value -gt $Version.Ubr) { return $true }
    }
    return $false
}

function Get-PreparationWindowsVersion {
    $os = Get-ItemProperty -LiteralPath 'HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion'
    $read = { param($Name) $property = $os.PSObject.Properties[$Name]; if ($null -ne $property) { $property.Value } }
    return [pscustomobject]@{
        Build = [int](& $read 'CurrentBuildNumber'); Ubr = [int](& $read 'UBR')
        DisplayVersion = [string](& $read 'DisplayVersion'); EditionId = [string](& $read 'EditionID')
    }
}

# What a move needs before the feature update: the newest cumulative update for
# this build, which Windows Update can offer only as optional
# (DeploymentAction=OptionalInstallation) and the ordinary pass never installs.
# Only before the move, and only Windows's own cumulative updates for this build;
# the known KB numbers name it in the log. Other optional updates are left alone.
function Find-PreparationPrerequisiteUpdate($Session) {
    if (-not $WindowsTarget) { return }
    $version = Get-PreparationWindowsVersion
    if (@(Get-PreparationSourceBuild) -notcontains $version.Build) { return }
    $searches = @("IsInstalled=0 and IsHidden=0 and Type='Software' and DeploymentAction='OptionalInstallation'")
    $offers = @()
    try { $offers = @(Invoke-PreparationSearch $Session $searches[0]) }
    catch {
        if ((Get-PreparationHResult $_.Exception) -ne $script:InvalidCriteria) { throw }
        # An older client that cannot ask for optional updates lists them as
        # browse-only instead.
        Write-AtlasTransitionEvidence "search not supported: $($searches[0])"
        $offers = @(Invoke-PreparationSearch $Session "IsInstalled=0 and IsHidden=0 and Type='Software' and BrowseOnly=1")
    }
    foreach ($update in $offers) {
        if ((Test-PreparationUpgradeCategory $update) -or [int]$update.Type -eq $script:DriverUpdate) { continue }
        $known = Test-PreparationKnownKb $update $PrerequisiteKb
        if (-not $known -and -not (Test-PreparationNewerRevision $update $version)) {
            Write-AtlasTransitionEvidence "optional update left: $(Format-PreparationOffer $update)"
            continue
        }
        Write-AtlasTransitionEvidence "prerequisite offer$(if ($known) { ' (a known KB)' }): $(Format-PreparationOffer $update)"
        $update
    }
}

# Waits for a Store call that returns $ResultType, reporting the search meanwhile.
function Wait-PreparationStoreCall($Operation, [type]$ResultType) {
    $asTask = [System.WindowsRuntimeSystemExtensions].GetMethods() | Where-Object {
        $_.Name -eq 'AsTask' -and $_.IsGenericMethod -and $_.GetGenericArguments().Count -eq 1 -and $_.GetParameters().Count -eq 1
    } | Select-Object -First 1
    $task = $asTask.MakeGenericMethod($ResultType).Invoke($null, @($Operation))
    $deadline = [DateTime]::UtcNow.AddMinutes(3)
    while (-not $task.Wait(2000)) {
        Write-PreparationState running store-search
        if ([DateTime]::UtcNow -gt $deadline) { throw 'Microsoft Store did not answer.' }
    }
    return $task.Result
}

function Wait-PreparationStoreSearch($Operation) {
    $resultType = [System.Collections.Generic.IReadOnlyList[Windows.ApplicationModel.Store.Preview.InstallControl.AppInstallItem]]
    return (Wait-PreparationStoreCall $Operation $resultType)
}

function New-PreparationStoreManager {
    if (-not (Get-AppxPackage -Name Microsoft.WindowsStore)) { throw (New-PreparationFailure 'Microsoft Store is not registered for this user. Open Store once, then try again.' 'store-missing') }
    return (Get-PreparationAppInstallManager)
}

function Invoke-PreparationStore {
    for ($pass = 0; $pass -lt $script:PreparationPasses; $pass++) {
        Assert-PreparationContinue
        if (-not (Test-PreparationNetwork)) { throw (New-Object System.Net.NetworkInformation.NetworkInformationException) }
        Write-PreparationState running store-search
        $manager = New-PreparationStoreManager
        # A retry must remove failed queue records before a fresh search.
        # This is the same queue recovery used by WinGet's Store installer.
        $cleared = @{}
        foreach ($previous in @($manager.AppInstallItems)) {
            $previousState = [string]$previous.GetCurrentStatus().InstallState
            if ($previousState -in @('Error','Canceled')) {
                $cleared[[string]$previous.PackageFamilyName] = $previousState
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
        Write-PreparationStoreRetried $cleared $items
        if ($items.Count -eq 0) { return }
        $deadline = [DateTime]::UtcNow.AddMinutes(30)
        $restarted = @{}
        $before = Get-PreparationPackageVersion
        try {
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
        }
        finally { Write-PreparationStoreItem $items $before }
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
    # A Store the user removed has nothing to check; preparation skipped it too.
    if (Test-PreparationStoreRemoved) { $pending = @() }
    else {
        Write-PreparationState running store-search
        $manager = New-PreparationStoreManager
        $options = New-Object Windows.ApplicationModel.Store.Preview.InstallControl.AppUpdateOptions
        $options.AllowForcedAppRestart = $false
        # This API queues found updates paused even when downloads are disabled.
        # Do not cancel another client's queue; the normal preparation pass resumes it.
        $options.AutomaticallyDownloadAndInstallUpdateIfFound = $false
        $found = @(Wait-PreparationStoreSearch ($manager.SearchForAllUpdatesAsync('', 'Atlas', $options)))
        $pending = @(@($found) + @($manager.AppInstallItems) | Where-Object { [string]$_.GetCurrentStatus().InstallState -ne 'Completed' })
    }
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

# Microsoft Store itself. Windows installed from old media and never updated
# before Atlas leaves a Store too old to update apps, so the Store and App
# Installer are brought up to date first. A Store the PC has but this user
# hasn't registered is registered before that. A Store that still fails gets one
# pass, per run, through the repairs below, each logged with what it changed.
$script:PreparationStoreFamily = 'Microsoft.WindowsStore_8wekyb3d8bbwe'
$script:PreparationAppInstallerFamily = 'Microsoft.DesktopAppInstaller_8wekyb3d8bbwe'
# The Store's id in its own catalogue, for winget's msstore source.
$script:PreparationStoreProductId = '9WZDNCRFJBMP'
# The Store, App Installer, the Store's purchase app and the frameworks Store
# apps run on: logged by version before and after.
$script:PreparationStoreInventoryNames = @(
    'Microsoft.WindowsStore', 'Microsoft.DesktopAppInstaller', 'Microsoft.StorePurchaseApp',
    'Microsoft.VCLibs.140.00*', 'Microsoft.UI.Xaml.*', 'Microsoft.NET.Native.Framework.*',
    'Microsoft.NET.Native.Runtime.*', 'Microsoft.WindowsAppRuntime.*')
# In order: wsreset -i, then App Installer (the newer copy this PC has, or one
# from Microsoft) and the Store through winget, then StoreFixer.
$script:PreparationStoreRepairs = @('wsreset', 'bootstrap', 'storefixer')
# Whether the bootstrap downloaded App Installer, rather than registering the
# copy this PC already had.
$script:PreparationStoreDownloaded = $false
$script:PreparationStoreRepairsRun = $false
# What happened to the Store in this run, for the app: store-updated,
# store-bootstrapped, store-repaired or store-skipped-removed.
$script:PreparationStoreOutcome = $null
# winget-cli's GitHub repository and its owner, by the ids GitHub gives them,
# so a renamed or replaced repository is refused.
$script:PreparationWingetRepository = 'microsoft/winget-cli'
$script:PreparationWingetRepositoryId = 197275130
$script:PreparationWingetOwnerId = 6154722
$script:PreparationMicrosoftPublisher = 'CN=Microsoft Corporation, O=Microsoft Corporation, L=Redmond, S=Washington, C=US'

function Write-PreparationStoreEvidence([string]$Text) {
    "Microsoft Store: $Text" | Add-Content -LiteralPath (Join-Path $JobPath 'updates.log')
    Write-AtlasTransitionEvidence "store: $Text"
}

function Get-PreparationStoreInventory {
    foreach ($name in $script:PreparationStoreInventoryNames) {
        foreach ($package in @(Get-AppxPackage -Name $name -ErrorAction SilentlyContinue | Sort-Object Name, Version)) {
            '{0} {1} {2} {3}' -f $package.Name, $package.Version, $package.Architecture, $package.Status
        }
    }
}

function Write-PreparationStoreInventory([string]$When) {
    $lines = @(Get-PreparationStoreInventory)
    Write-PreparationStoreEvidence "packages $When`: $(if ($lines.Count) { $lines -join '; ' } else { 'none for this user' })"
}

# This user's packages by family, each at its newest version.
function Get-PreparationPackageVersion {
    $versions = @{}
    foreach ($package in @(Get-AppxPackage -ErrorAction SilentlyContinue)) {
        $family = [string]$package.PackageFamilyName
        if (-not $versions.ContainsKey($family) -or [version]$package.Version -gt [version]$versions[$family]) { $versions[$family] = [string]$package.Version }
    }
    return $versions
}

# Each Store item a pass waited for: its family, its product id, the version
# this user had before and has now, and how it ended.
function Write-PreparationStoreItem($Items, [hashtable]$Before) {
    try {
        $after = Get-PreparationPackageVersion
        foreach ($item in @($Items)) {
            $family = [string]$item.PackageFamilyName
            $state = try { [string]$item.GetCurrentStatus().InstallState } catch { 'unreadable' }
            $from = if ($Before.ContainsKey($family)) { $Before[$family] } else { 'none' }
            $to = if ($after.ContainsKey($family)) { $after[$family] } else { 'none' }
            $product = if ([string]$item.ProductId) { " ($($item.ProductId))" } else { '' }
            Write-PreparationStoreEvidence "item $family$product`: $from -> $to, $state"
        }
    }
    catch { Write-PreparationStoreEvidence "the Store items could not be listed: $($_.Exception.Message)" }
}

# What became of the items an earlier round left in Error or Canceled. The fresh
# search decides: an item the Store offers again is waited for again and fails the
# pass if it fails again; one it no longer offers is up to date, as a busy Store
# can report Error for an update it has already installed.
function Write-PreparationStoreRetried([hashtable]$Cleared, $Items) {
    if ($Cleared.Count -eq 0) { return }
    $offered = @($Items | ForEach-Object { [string]$_.PackageFamilyName })
    $versions = Get-PreparationPackageVersion
    foreach ($family in @($Cleared.Keys | Sort-Object)) {
        if ($offered -contains $family) {
            Write-PreparationStoreEvidence "item $family`: offered again after it ended $($Cleared[$family]); updating it again"
            continue
        }
        $held = if ($versions.ContainsKey($family)) { "this user has $($versions[$family]), so it's up to date" } else { "this user doesn't have it" }
        Write-PreparationStoreEvidence "item $family`: no longer offered after it ended $($Cleared[$family]); $held"
    }
}

# The Store registered and working for this user, by version; empty when it isn't.
function Get-PreparationStoreVersion {
    $package = @(Get-AppxPackage -Name Microsoft.WindowsStore -ErrorAction SilentlyContinue |
            Where-Object { [string]$_.Status -eq 'Ok' } | Sort-Object Version -Descending) | Select-Object -First 1
    if ($null -eq $package) { return '' }
    return [string]$package.Version
}

# Atlas 0.5.0's "Disable Microsoft Store" and Atlas 0.6's Microsoft Store toggle
# both record the choice here; state 0 is removed. A Store the user brought back
# by hand since is updated like any other.
function Test-PreparationStoreRemoved {
    $record = Get-ItemProperty -LiteralPath 'HKLM:\SOFTWARE\AtlasOS\Services\MicrosoftStore' -Name state -ErrorAction SilentlyContinue
    if ($null -eq $record -or [int64]$record.state -ne 0) { return $false }
    return -not (Get-PreparationStoreVersion)
}

function Set-PreparationStoreOutcome([string]$Outcome) {
    # A repair says more than the update it led to.
    if ($script:PreparationStoreOutcome -in @('store-bootstrapped', 'store-repaired') -and $Outcome -eq 'store-updated') { return }
    $script:PreparationStoreOutcome = $Outcome
}

# What the finished run tells the app beyond its status.
function Get-PreparationOutcomeDetail {
    if ($script:PreparationStoreOutcome) { return @{ storeOutcome = $script:PreparationStoreOutcome } }
    return @{}
}

# The Store's install manager, without the check New-PreparationStoreManager
# makes, for following a reinstall of a Store that isn't registered yet.
function Get-PreparationAppInstallManager {
    Add-Type -AssemblyName System.Runtime.WindowsRuntime
    $null = [Windows.ApplicationModel.Store.Preview.InstallControl.AppInstallManager, Windows.ApplicationModel.Store.Preview.InstallControl, ContentType=WindowsRuntime]
    $null = [Windows.ApplicationModel.Store.Preview.InstallControl.AppInstallItem, Windows.ApplicationModel.Store.Preview.InstallControl, ContentType=WindowsRuntime]
    $null = [Windows.ApplicationModel.Store.Preview.InstallControl.AppUpdateOptions, Windows.ApplicationModel.Store.Preview.InstallControl, ContentType=WindowsRuntime]
    return New-Object Windows.ApplicationModel.Store.Preview.InstallControl.AppInstallManager
}

# Follows one Store download to its end. A queued or paused one is restarted
# once, as WinGet does; any other stop fails.
function Wait-PreparationStoreItem($Manager, $Item, [string]$Stage, [int]$Minutes = 30) {
    $deadline = [DateTime]::UtcNow.AddMinutes($Minutes)
    $restarted = $false
    while ($true) {
        Assert-PreparationContinue
        $status = $Item.GetCurrentStatus()
        $state = [string]$status.InstallState
        if ($state -eq 'Completed') { return }
        if ($state -in @('ReadyToDownload', 'Paused') -and -not $restarted) {
            $Manager.Restart($Item.ProductId)
            $restarted = $true
        }
        elseif ($state -in @('Error', 'Canceled', 'Paused', 'PausedLowBattery', 'PausedWiFiRecommended', 'PausedWiFiRequired')) {
            throw (New-PreparationStoreFailure $Item.PackageFamilyName $state $status.ErrorCode)
        }
        Write-PreparationState running $Stage -Detail @{ percent = [int][Math]::Max(0, [Math]::Min(100, [double]$status.PercentComplete)) }
        if ([DateTime]::UtcNow -gt $deadline) { throw (New-PreparationFailure "Microsoft Store has not finished updating $($Item.PackageFamilyName)." 'store-timeout') }
        Start-Sleep -Seconds 2
    }
}

# Asks the Store to update itself, then App Installer, by package family, and
# waits for each. App Installer only helps; a Store that can't update fails.
# Returns whether either was updated.
function Update-PreparationStoreItself {
    $manager = New-PreparationStoreManager
    $itemType = [Windows.ApplicationModel.Store.Preview.InstallControl.AppInstallItem]
    $updated = $false
    foreach ($family in @($script:PreparationStoreFamily, $script:PreparationAppInstallerFamily)) {
        Assert-PreparationContinue
        try {
            $item = Wait-PreparationStoreCall ($manager.UpdateAppByPackageFamilyNameAsync($family)) $itemType
            if ($null -eq $item) {
                Write-PreparationStoreEvidence "$family has no update"
                continue
            }
            Write-PreparationStoreEvidence "$family is out of date; updating it"
            $before = Get-PreparationPackageVersion
            try { Wait-PreparationStoreItem $manager $item store-self-update }
            finally { Write-PreparationStoreItem @($item) $before }
            $updated = $true
        }
        catch {
            if ($family -eq $script:PreparationStoreFamily -or -not (Test-PreparationStoreRepairable $_.Exception)) { throw }
            Write-PreparationStoreEvidence "$family could not be updated, going on: $($_.Exception.Message)"
        }
    }
    return $updated
}

# Failures a Store repair can help with. Not a paused queue the user resolves,
# an app in use, a busy installer, the connection, the wrong account or Stop.
function Test-PreparationStoreRepairable([Exception]$Exception) {
    if ($Exception -is [OperationCanceledException] -or $Exception -is [System.Net.NetworkInformation.NetworkInformationException]) { return $false }
    $detail = Get-PreparationFailureDetail $Exception
    if ($detail.ContainsKey('reason') -and $detail.reason -in @('store-paused-battery', 'store-paused-network', 'session-owner')) { return $false }
    if ($detail.ContainsKey('errorCode') -and $detail.errorCode -in @('0x80073D02', '0x80240016')) { return $false }
    return $true
}

# The Store stage of a preparation run: skipped when the user removed the
# Store; otherwise a Store the PC has but this user hasn't registered is
# registered, the Store and App Installer update themselves, then the apps, and
# the repairs follow when that fails.
function Invoke-PreparationStoreStage {
    if (Test-PreparationStoreRemoved) {
        Write-PreparationStoreEvidence 'turned off for this user by the recorded choice (HKLM\SOFTWARE\AtlasOS\Services\MicrosoftStore state 0); Store app updates skipped. Other accounts may still have the Store; this pass only ever updates the signed-in user'
        Set-PreparationStoreOutcome 'store-skipped-removed'
        return
    }
    Write-PreparationStoreInventory 'before'
    # Staged or provisioned but not registered (or not working) for this user:
    # registering it brings it back at once, which wsreset -i doesn't.
    if (-not (Get-PreparationStoreVersion)) {
        Write-PreparationStoreEvidence 'not registered and working for this user; registering it'
        try {
            [void](Register-PreparationStore)
            if (Get-PreparationStoreVersion) { Set-PreparationStoreOutcome 'store-repaired' }
        }
        catch {
            if ($_.Exception -is [OperationCanceledException]) { throw }
            Write-PreparationStoreEvidence "registering it failed: $($_.Exception.Message)"
        }
    }
    try {
        if (Update-PreparationStoreItself) { Set-PreparationStoreOutcome 'store-updated' }
        Invoke-PreparationStoreWithRetry
        Write-PreparationStoreInventory 'after'
        return
    }
    catch {
        if (-not (Test-PreparationStoreRepairable $_.Exception)) { throw }
        $failure = $_.Exception
    }
    Repair-PreparationStore $failure
}

# One pass through the repairs. After each that changed something, the Store
# is asked to update itself and the apps again; the first that works ends it.
function Repair-PreparationStore([Exception]$Failure) {
    if ($script:PreparationStoreRepairsRun) { throw $Failure }
    $script:PreparationStoreRepairsRun = $true
    $code = (Get-PreparationFailureDetail $Failure)['errorCode']
    Write-PreparationStoreEvidence "updating failed ($($Failure.Message)$(if ($code) { ", $code" })); repairing"
    $last = $Failure
    foreach ($repair in $script:PreparationStoreRepairs) {
        Assert-PreparationContinue
        Write-PreparationState running store-repair
        try { $changed = [bool](Invoke-PreparationStoreRepair $repair | Select-Object -Last 1) }
        catch {
            if ($_.Exception -is [OperationCanceledException]) { throw }
            Write-PreparationStoreEvidence "$repair failed: $($_.Exception.Message)"
            continue
        }
        if (-not $changed) {
            Write-PreparationStoreEvidence "$repair changed nothing"
            continue
        }
        Write-PreparationStoreEvidence "$repair done; trying the Store again"
        try {
            [void](Update-PreparationStoreItself)
            Invoke-PreparationStoreWithRetry
            Set-PreparationStoreOutcome $(if ($repair -eq 'bootstrap' -and $script:PreparationStoreDownloaded) { 'store-bootstrapped' } else { 'store-repaired' })
            Write-PreparationStoreEvidence "works again after $repair"
            Write-PreparationStoreInventory 'after'
            return
        }
        catch {
            if (-not (Test-PreparationStoreRepairable $_.Exception)) { throw }
            $last = $_.Exception
            Write-PreparationStoreEvidence "still failing after $repair`: $($last.Message)"
        }
    }
    Write-PreparationStoreInventory 'after'
    $hresult = if ($code) { [Convert]::ToInt32($code, 16) } else { 0 }
    throw (New-PreparationFailure "Microsoft Store couldn't be repaired: $($last.Message)" 'store-repair-failed' $hresult)
}

function Invoke-PreparationStoreRepair([string]$Repair) {
    switch ($Repair) {
        'wsreset' { Invoke-PreparationWsReset }
        'bootstrap' { Install-PreparationStoreFromMicrosoft }
        'storefixer' { Invoke-PreparationStoreFixer }
    }
}

# Starts a program in this session and waits for it, reporting the repair
# meanwhile. Returns its exit code, or $null if it's still running at the end.
function Invoke-PreparationStoreProcess([string]$FilePath, [string]$Arguments, [int]$Minutes, [switch]$Hidden) {
    $start = @{ FilePath = $FilePath; PassThru = $true }
    if ($Arguments) { $start.ArgumentList = $Arguments }
    if ($Hidden) { $start.WindowStyle = 'Hidden' }
    $process = Start-Process @start
    $deadline = [DateTime]::UtcNow.AddMinutes($Minutes)
    while (-not $process.WaitForExit(2000)) {
        Assert-PreparationContinue
        Write-PreparationState running store-repair
        if ([DateTime]::UtcNow -gt $deadline) { return $null }
    }
    return $process.ExitCode
}

# wsreset -i. The switch isn't documented: it runs without a window, registers
# the Store's frameworks again and updates the Store's purchase app in the
# background. It doesn't register a Store this user hasn't registered or change
# the Store's or App Installer's version. Plain wsreset opens the Store and isn't
# used.
function Get-PreparationWsResetPath { [IO.Path]::Combine([Environment]::GetFolderPath('System'), 'WSReset.exe') }

function Invoke-PreparationWsReset {
    $path = Get-PreparationWsResetPath
    if (-not [IO.File]::Exists($path)) {
        Write-PreparationStoreEvidence 'wsreset: WSReset.exe is missing'
        return $false
    }
    $exit = Invoke-PreparationStoreProcess $path '-i' 5
    Write-PreparationStoreEvidence "wsreset -i exited $(if ($null -eq $exit) { 'not yet, after 5 minutes' } else { $exit })"
    Wait-PreparationStoreQueue
    Write-PreparationStoreInventory 'after wsreset -i'
    return $exit -eq 0
}

# Follows whatever the Store's install service has queued, such as the purchase
# app wsreset -i updates, to its end, and logs it.
function Wait-PreparationStoreQueue {
    try {
        $manager = Get-PreparationAppInstallManager
        $queued = @($manager.AppInstallItems | Where-Object { [string]$_.GetCurrentStatus().InstallState -ne 'Completed' })
        if ($queued.Count -eq 0) { return }
        $before = Get-PreparationPackageVersion
        try { foreach ($item in $queued) { Wait-PreparationStoreItem $manager $item store-repair 15 } }
        finally { Write-PreparationStoreItem $queued $before }
    }
    catch {
        if ($_.Exception -is [OperationCanceledException]) { throw }
        Write-PreparationStoreEvidence "what wsreset -i queued didn't finish: $($_.Exception.Message)"
    }
}

# A file this run downloaded or unpacked: Microsoft's valid signature, checked
# before Windows installs it.
function Assert-PreparationMicrosoftSignature([string]$Path) {
    $signature = Get-AuthenticodeSignature -LiteralPath $Path
    if ($signature.Status -ne [Management.Automation.SignatureStatus]::Valid -or $null -eq $signature.SignerCertificate -or
        $signature.SignerCertificate.Subject -notmatch '(^|,\s*)CN=Microsoft Corporation(,|$)') {
        throw "$([IO.Path]::GetFileName($Path)) isn't signed by Microsoft ($($signature.Status))."
    }
}

# HTTPS only, no user information, at most $MaximumBytes, within $Seconds.
function Save-PreparationDownload([uri]$Uri, [string]$Destination, [long]$MaximumBytes, [int]$Seconds = 600, [switch]$GitHubApi) {
    if ($Uri.Scheme -cne 'https' -or $Uri.UserInfo) { throw "Only HTTPS downloads are allowed: $Uri" }
    Add-Type -AssemblyName System.Net.Http
    $handler = New-Object Net.Http.HttpClientHandler
    $handler.MaxAutomaticRedirections = 5
    $client = New-Object Net.Http.HttpClient($handler)
    $client.Timeout = [TimeSpan]::FromSeconds($Seconds)
    $client.DefaultRequestHeaders.UserAgent.ParseAdd('AtlasOS-Preparation')
    if ($GitHubApi) { $client.DefaultRequestHeaders.Accept.ParseAdd('application/vnd.github+json') }
    $response = $null
    $output = $null
    try {
        $response = $client.GetAsync($Uri, [Net.Http.HttpCompletionOption]::ResponseHeadersRead).GetAwaiter().GetResult()
        if (-not $response.IsSuccessStatusCode) { throw "Downloading $Uri failed with HTTP status $([int]$response.StatusCode)." }
        if ($response.RequestMessage.RequestUri.Scheme -cne 'https') { throw "Downloading $Uri left HTTPS." }
        $stream = $response.Content.ReadAsStreamAsync().GetAwaiter().GetResult()
        $output = [IO.File]::Open($Destination, [IO.FileMode]::CreateNew, [IO.FileAccess]::Write, [IO.FileShare]::None)
        $buffer = New-Object byte[] 65536
        [long]$total = 0
        while (($read = $stream.Read($buffer, 0, $buffer.Length)) -gt 0) {
            $total += $read
            if ($total -gt $MaximumBytes) { throw "Downloading $Uri passed $MaximumBytes bytes." }
            $output.Write($buffer, 0, $read)
        }
    }
    finally {
        if ($null -ne $output) { $output.Dispose() }
        if ($null -ne $response) { $response.Dispose() }
        $client.Dispose()
    }
}

# The latest stable winget-cli release, from the repository with the expected
# ids, and the SHA-256 GitHub records for each file.
function Get-PreparationWingetRelease([string]$Folder) {
    $api = "https://api.github.com/repos/$script:PreparationWingetRepository"
    $repositoryFile = Join-Path $Folder 'repository.json'
    Save-PreparationDownload $api $repositoryFile 1MB 60 -GitHubApi
    $repository = [IO.File]::ReadAllText($repositoryFile) | ConvertFrom-Json
    if ([long]$repository.id -ne $script:PreparationWingetRepositoryId -or [long]$repository.owner.id -ne $script:PreparationWingetOwnerId -or
        [string]$repository.full_name -cne $script:PreparationWingetRepository) {
        throw "GitHub answered for a repository other than $script:PreparationWingetRepository."
    }
    $releaseFile = Join-Path $Folder 'release.json'
    Save-PreparationDownload "$api/releases/latest" $releaseFile 4MB 60 -GitHubApi
    $release = [IO.File]::ReadAllText($releaseFile) | ConvertFrom-Json
    if ($release.draft -or $release.prerelease -or [string]$release.tag_name -notmatch '^v?\d+\.\d+\.\d+$') {
        throw 'The latest winget-cli release is not a stable release.'
    }
    return $release
}

# Downloads one file of $Release, checking its size and SHA-256 against what
# GitHub records for it.
function Save-PreparationReleaseAsset($Release, [string]$Name, [string]$Folder) {
    $asset = @($Release.assets | Where-Object { [string]$_.name -ceq $Name })
    if ($asset.Count -ne 1) { throw "The winget-cli release has no single $Name." }
    $asset = $asset[0]
    $digest = [regex]::Match([string]$asset.digest, '^sha256:([0-9a-fA-F]{64})$')
    $expected = "https://github.com/$script:PreparationWingetRepository/releases/download/$($Release.tag_name)/$Name"
    if (-not $digest.Success -or [string]$asset.browser_download_url -cne $expected -or [long]$asset.size -le 0 -or [long]$asset.size -gt 1GB) {
        throw "The winget-cli release lists $Name without a SHA-256, a size or its own address."
    }
    $path = Join-Path $Folder $Name
    Save-PreparationDownload $expected $path ([long]$asset.size) 1800
    $hash = (Get-FileHash -LiteralPath $path -Algorithm SHA256).Hash
    if ((Get-Item -LiteralPath $path).Length -ne [long]$asset.size -or -not $hash.Equals($digest.Groups[1].Value, [StringComparison]::OrdinalIgnoreCase)) {
        throw "$Name doesn't match the SHA-256 GitHub records for it."
    }
    return $path
}

# App Installer staged or provisioned on this PC in a newer version than this
# user has: registering it needs no download. Returns whether it did.
function Register-PreparationNewerAppInstaller {
    $mine = @(Get-AppxPackage -Name Microsoft.DesktopAppInstaller -ErrorAction SilentlyContinue | Sort-Object { [version]$_.Version } -Descending) | Select-Object -First 1
    $current = if ($null -ne $mine) { [version]$mine.Version } else { $null }
    $versions = @(Get-AppxPackage -AllUsers -Name Microsoft.DesktopAppInstaller -ErrorAction SilentlyContinue | ForEach-Object { [version]$_.Version })
    try {
        $versions += @(Get-AppxProvisionedPackage -Online -ErrorAction Stop | Where-Object { [string]$_.DisplayName -eq 'Microsoft.DesktopAppInstaller' } | ForEach-Object { [version]$_.Version })
    }
    catch { Write-PreparationStoreEvidence "provisioned packages could not be read: $($_.Exception.Message)" }
    $newest = @($versions | Sort-Object -Descending) | Select-Object -First 1
    if ($null -eq $newest -or ($null -ne $current -and $current -ge $newest)) {
        Write-PreparationStoreEvidence "App Installer: this user has $(if ($current) { $current } else { 'none' }), and this PC has nothing newer"
        return $false
    }
    Add-AppxPackage -RegisterByFamilyName -MainPackage $script:PreparationAppInstallerFamily -ErrorAction Stop
    $now = @(Get-AppxPackage -Name Microsoft.DesktopAppInstaller -ErrorAction SilentlyContinue | Sort-Object { [version]$_.Version } -Descending) | Select-Object -First 1
    Write-PreparationStoreEvidence "App Installer: registered the copy this PC has, $(if ($current) { $current } else { 'none' }) -> $(if ($now) { $now.Version } else { 'none' })"
    return $true
}

# App Installer: the newer copy this PC has, or else one with the frameworks
# winget-cli's release says it needs, from Microsoft's own release; then
# Microsoft Store itself from the Store's catalogue through winget. Downloads go
# to this job's folder, which only administrators can change.
function Install-PreparationStoreFromMicrosoft {
    $winget = $null
    try {
        if (Register-PreparationNewerAppInstaller) { $winget = Get-PreparationWingetPath }
    }
    catch {
        if ($_.Exception -is [OperationCanceledException]) { throw }
        Write-PreparationStoreEvidence "bootstrap: the App Installer this PC has didn't give a usable winget: $($_.Exception.Message)"
    }
    if (-not $winget) {
        Save-PreparationAppInstaller
        $winget = Get-PreparationWingetPath
    }
    Assert-PreparationWingetStoreSource $winget
    $arguments = "install --exact --id $script:PreparationStoreProductId --source msstore --silent --accept-source-agreements --accept-package-agreements --disable-interactivity"
    $exit = Invoke-PreparationStoreProcess $winget $arguments 20 -Hidden
    # 0x8A15002B: nothing newer to install, so the Store is already current.
    Write-PreparationStoreEvidence "bootstrap: winget install of Microsoft Store exited $exit"
    if ($exit -notin @(0, -1978335189)) { throw "winget couldn't install Microsoft Store (exit $exit)." }
    return $true
}

# App Installer and its frameworks from the latest winget-cli release.
function Save-PreparationAppInstaller {
    $folder = Join-Path $JobPath 'store-bootstrap'
    if (Test-Path -LiteralPath $folder) { Remove-Item -LiteralPath $folder -Recurse -Force }
    $null = New-Item -ItemType Directory -Path $folder
    $architecture = switch ($env:PROCESSOR_ARCHITECTURE) { 'AMD64' { 'x64' } 'ARM64' { 'arm64' } 'x86' { 'x86' } }
    if (-not $architecture) { throw "No App Installer frameworks for $env:PROCESSOR_ARCHITECTURE." }
    $release = Get-PreparationWingetRelease $folder
    Write-PreparationStoreEvidence "bootstrap: winget-cli $($release.tag_name)"
    $bundle = Save-PreparationReleaseAsset $release 'Microsoft.DesktopAppInstaller_8wekyb3d8bbwe.msixbundle' $folder
    $archive = Save-PreparationReleaseAsset $release 'DesktopAppInstaller_Dependencies.zip' $folder
    $unpacked = Join-Path $folder 'dependencies'
    Expand-Archive -LiteralPath $archive -DestinationPath $unpacked
    $dependencies = @(Get-ChildItem -LiteralPath (Join-Path $unpacked $architecture) -Filter '*.appx' -File | ForEach-Object { $_.FullName })
    foreach ($file in @($bundle) + $dependencies) { Assert-PreparationMicrosoftSignature $file }
    Write-PreparationState running store-repair
    Add-AppxPackage -Path $bundle -DependencyPath $dependencies -ForceApplicationShutdown -ErrorAction Stop
    $script:PreparationStoreDownloaded = $true
    Write-PreparationStoreEvidence "bootstrap: installed App Installer with $(@($dependencies | ForEach-Object { [IO.Path]::GetFileName($_) }) -join ', ')"
}

# winget.exe from this user's App Installer: Microsoft's package under
# WindowsApps, with a valid Microsoft signature.
function Get-PreparationWingetPath {
    $windowsApps = [IO.Path]::Combine([Environment]::GetFolderPath('ProgramFiles'), 'WindowsApps').TrimEnd('\') + '\'
    foreach ($package in @(Get-AppxPackage -Name Microsoft.DesktopAppInstaller -ErrorAction SilentlyContinue | Sort-Object Version -Descending)) {
        if ([string]$package.PackageFamilyName -cne $script:PreparationAppInstallerFamily -or [string]$package.Publisher -cne $script:PreparationMicrosoftPublisher -or
            -not $package.InstallLocation) { continue }
        $location = [IO.Path]::GetFullPath([string]$package.InstallLocation).TrimEnd('\') + '\'
        if (-not $location.StartsWith($windowsApps, [StringComparison]::OrdinalIgnoreCase)) { continue }
        $path = Join-Path $location 'winget.exe'
        if (-not [IO.File]::Exists($path)) { continue }
        Assert-PreparationMicrosoftSignature $path
        return $path
    }
    throw 'App Installer has no winget.exe for this user.'
}

# winget's msstore source as Microsoft registers it.
function Assert-PreparationWingetStoreSource([string]$Winget) {
    $output = @(& $Winget source export msstore --disable-interactivity 2>&1)
    if ($LASTEXITCODE -ne 0) { throw "winget couldn't list its msstore source (exit $LASTEXITCODE)." }
    $source = (@($output | ForEach-Object { $_.ToString() }) -join [Environment]::NewLine) | ConvertFrom-Json
    if ([string]$source.Name -cne 'msstore' -or [string]$source.Type -cne 'Microsoft.Rest' -or
        [string]$source.Arg -cne 'https://storeedgefd.dsx.mp.microsoft.com/v9.0' -or [string]$source.Identifier -cne 'StoreEdgeFD') {
        throw "winget's msstore source isn't Microsoft's."
    }
}

# Registers Microsoft Store for this user: from the newest package any account
# has, staged ones included, by its manifest under WindowsApps, or by its
# family. That brings an unregistered Store back at once.
function Register-PreparationStore {
    $windowsApps = [IO.Path]::Combine([Environment]::GetFolderPath('ProgramFiles'), 'WindowsApps').TrimEnd('\') + '\'
    $installed = @(Get-AppxPackage -AllUsers -Name Microsoft.WindowsStore -ErrorAction SilentlyContinue | Where-Object {
            [string]$_.PackageFamilyName -ceq $script:PreparationStoreFamily -and $_.InstallLocation -and
            ([IO.Path]::GetFullPath([string]$_.InstallLocation).TrimEnd('\') + '\').StartsWith($windowsApps, [StringComparison]::OrdinalIgnoreCase)
        } | Sort-Object Version -Descending)
    $manifest = if ($installed.Count) { Join-Path ([string]$installed[0].InstallLocation) 'AppxManifest.xml' }
    if ($manifest -and [IO.File]::Exists($manifest)) {
        Add-AppxPackage -DisableDevelopmentMode -Register $manifest -ErrorAction Stop
        Write-PreparationStoreEvidence "register: registered Microsoft Store $($installed[0].Version) from its installed manifest"
    }
    else {
        Add-AppxPackage -RegisterByFamilyName -MainPackage $script:PreparationStoreFamily -ErrorAction Stop
        Write-PreparationStoreEvidence 'register: registered Microsoft Store by its family'
    }
    return $true
}

# StoreFixer runs as TrustedInstaller, which only Atlas 0.6's own "Fix MS Store
# Issues" can start safely; an older Atlas has no such launcher, so this repair
# is left out there.
function Invoke-PreparationStoreFixer {
    $windows = [Environment]::GetFolderPath('Windows')
    $launcher = [IO.Path]::Combine($windows, 'AtlasModules\Scripts\Entry\Invoke-AtlasToggleLauncher.cmd')
    $definition = [IO.Path]::Combine($windows, 'AtlasModules\Toggles\Troubleshooting\FixMSStoreIssues.psd1')
    $shortcut = [IO.Path]::Combine($windows, 'AtlasDesktop\9. Troubleshooting\Fix MS Store Issues.cmd')
    if (-not ([IO.File]::Exists($launcher) -and [IO.File]::Exists($definition))) {
        Write-PreparationStoreEvidence "StoreFixer: this PC has no Atlas 0.6 Fix MS Store Issues to start it; left out"
        return $false
    }
    $cmd = [IO.Path]::Combine([Environment]::GetFolderPath('System'), 'cmd.exe')
    $exit = Invoke-PreparationStoreProcess $cmd "/d /s /c `"`"$launcher`" FixMSStoreIssues Run `"$shortcut`" /silent`"" 15 -Hidden
    Write-PreparationStoreEvidence "StoreFixer exited $(if ($null -eq $exit) { 'not yet, after 15 minutes' } else { $exit })"
    return $exit -eq 0
}

function Invoke-PreparationUpdates {
    try {
        # The last value only: stray pipeline output must not become the status.
        if ((Invoke-PreparationWindows | Select-Object -Last 1) -eq 'reboot') { return 'reboot' }
        Invoke-PreparationStoreStage
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

. (Join-Path $PSScriptRoot 'WindowsTransition.ps1')
. (Join-Path $PSScriptRoot 'RegistryFile.ps1')

# How long to wait for Windows Update to read a new target; how long it may then
# take to offer the release, and the waits between searches meanwhile (the last
# repeats); and how many times a run may restart Windows Update for it.
$script:PreparationPolicyWaitSeconds = 120
$script:PreparationOfferWindowSeconds = 600
$script:PreparationOfferBackoff = @(30, 60, 90, 120)
$script:PreparationServiceRestartLimit = 2
$script:PreparationServiceRestarts = 0
$script:PreparationTargetReread = $false

# The upgrades category, where Windows Update lists feature updates and
# enablement packages.
$script:UpgradesCategory = '3689BDC8-B205-4AF4-8D4A-A63924C5E9D5'
# WU_E_WU_DISABLED, WU_E_CALL_CANCELLED_BY_POLICY and ERROR_SERVICE_DISABLED:
# something turned Windows Update off again.
$script:UpdateAccessCodes = @(-2145124306, -2145124305, -2147023838)

function Get-PreparationSourceBuild { if ($SourceBuilds) { @($SourceBuilds -split ',' | ForEach-Object { [int]$_ }) } }

# Changes every boot, so a commit can be tied to the boot it happened in.
function Get-PreparationBootId {
    $boot = Get-AtlasTransitionValue 'SYSTEM\CurrentControlSet\Control\Session Manager\Memory Management\PrefetchParameters' 'BootId'
    if ($boot.Present) { return "boot:$($boot.Data)" }
    return 'time:{0:yyyy-MM-ddTHH:mm}' -f (Get-CimInstance -ClassName Win32_OperatingSystem).LastBootUpTime.ToUniversalTime()
}

# What Windows Update itself believes it was asked for; a diagnostic, never a gate.
function Get-PreparationPolicyState {
    $value = Get-AtlasTransitionValue 'SOFTWARE\Microsoft\WindowsUpdate\UpdatePolicy\PolicyState' 'TargetReleaseVersion'
    if ($value.Present) { return [string]$value.Data }
    return ''
}

# Windows 11 hardware this PC lacks, where Windows says: TPM 2.0 and UEFI firmware.
# Processor support has no reliable local answer and is not guessed.
function Get-PreparationHardwareGap {
    try {
        $tpm = Get-CimInstance -Namespace 'root\cimv2\Security\MicrosoftTpm' -ClassName Win32_Tpm -ErrorAction Stop
        if ($null -eq $tpm -or [string]$tpm.SpecVersion -notmatch '^\s*2\.0') { 'tpm' }
    }
    catch { Write-AtlasTransitionEvidence "TPM could not be read: $($_.Exception.Message)" }
    $firmware = Get-AtlasTransitionValue 'SYSTEM\CurrentControlSet\Control' 'PEFirmwareType'
    if ($firmware.Present -and [int64]$firmware.Data -ne 2) { 'uefi' }
}

# Whether a Windows Update history entry is the target's feature update: the one
# Atlas installed, by its id, or one whose title names the target release. Never
# by KB number alone: the offer can carry the KB number of a monthly update.
function Test-PreparationFeatureHistoryEntry([string]$Title, [string]$Id, [string]$UpdateId) {
    return [bool](($UpdateId -and $Id -eq $UpdateId) -or (Test-PreparationTargetTitle ([pscustomobject]@{ Title = $Title })))
}

# Windows Update history entries for the target's feature update.
function Get-PreparationFeatureHistory([string]$UpdateId = '') {
    $searcher = (New-Object -ComObject Microsoft.Update.Session).CreateUpdateSearcher()
    $count = [Math]::Min([int]$searcher.GetTotalHistoryCount(), 200)
    if ($count -le 0) { return }
    foreach ($entry in $searcher.QueryHistory(0, $count)) {
        $title = [string]$entry.Title
        $id = try { [string]$entry.UpdateIdentity.UpdateID } catch { '' }
        if (Test-PreparationFeatureHistoryEntry $title $id $UpdateId) {
            [pscustomobject]@{ Date = ([DateTime]$entry.Date).ToUniversalTime(); ResultCode = [int]$entry.ResultCode; HResult = [int]$entry.HResult; Title = $title }
        }
    }
}

function Restart-PreparationUpdateService {
    # Never while Windows Update is installing something.
    if ((New-Object -ComObject Microsoft.Update.Installer).IsBusy) { return $false }
    Restart-Service -Name wuauserv -Force -ErrorAction Stop
    return $true
}

# The installed feature update, found again by its id for the installer that
# commits it: an installer with no updates refuses the call (WU_E_NOT_INITIALIZED).
# While the restart is owed, the search still returns it, as not installed.
function Invoke-PreparationCommitCall([string]$UpdateId) {
    $installer = New-Object -ComObject Microsoft.Update.Installer
    if ($UpdateId) {
        $searcher = New-PreparationSearcher (New-Object -ComObject Microsoft.Update.Session)
        $updates = New-Object -ComObject Microsoft.Update.UpdateColl
        # The local cache first; Windows Update itself when the cache lacks it.
        foreach ($online in @($false, $true)) {
            $searcher.Online = $online
            try { foreach ($update in $searcher.Search("UpdateID='$UpdateId'").Updates) { [void]$updates.Add($update) } }
            catch { Write-AtlasTransitionEvidence "commit: search by id (online $online) failed: $($_.Exception.Message)" }
            if ($updates.Count -gt 0) { break }
        }
        Write-AtlasTransitionEvidence "commit: found $($updates.Count) update(s) with id $UpdateId"
        if ($updates.Count -gt 0) { $installer.Updates = $updates }
    }
    # IUpdateInstaller4 is hidden in the type library, so PowerShell may not list
    # Commit; IDispatch still resolves it by name.
    if ($null -ne $installer.PSObject.Methods['Commit']) { $installer.Commit(0) }
    else { [void][__ComObject].InvokeMember('Commit', [Reflection.BindingFlags]::InvokeMethod, $null, $installer, @(0)) }
}

# Finds the target's feature update among the upgrades Windows Update offers: the
# one whose title names the target release, whatever its KB. A known KB number
# wins when several do. Any other upgrade is logged and left alone.
function Find-PreparationFeatureOffer($Session) {
    $base = "IsInstalled=0 and IsHidden=0 and Type='Software' and CategoryIDs contains '$script:UpgradesCategory'"
    # Without DeploymentAction, a search means Installation; an optional offer
    # needs asking for.
    foreach ($criteria in @($base, "$base and DeploymentAction='OptionalInstallation'")) {
        try { $offers = @(Invoke-PreparationSearch $Session $criteria) }
        catch {
            if ((Get-PreparationHResult $_.Exception) -ne $script:InvalidCriteria) { throw }
            Write-AtlasTransitionEvidence "search not supported: $criteria"
            continue
        }
        Write-AtlasTransitionEvidence "searched: $criteria ($($offers.Count) offer(s))"
        $known = @(); $titled = @()
        foreach ($update in $offers) {
            if (Test-PreparationKnownKb $update $FeatureKb) { $known += $update }
            elseif (Test-PreparationTargetTitle $update) { $titled += $update }
            else { Write-AtlasTransitionEvidence "unexpected-offer, not installed: $(Format-PreparationOffer $update)" }
        }
        $chosen = if ($known.Count -gt 0) { $known[0] } elseif ($titled.Count -eq 1) { $titled[0] }
        if ($null -eq $chosen -and $titled.Count -gt 1) {
            foreach ($update in $titled) { Write-AtlasTransitionEvidence "unexpected-offer, one of several for $WindowsTarget, not installed: $(Format-PreparationOffer $update)" }
            throw (New-AtlasTransitionFailure "Windows Update offers $($titled.Count) different updates to $WindowsTarget, so Atlas did not choose one." 'feature-failed')
        }
        if ($null -ne $chosen) {
            foreach ($update in @($known) + @($titled)) {
                if (-not [object]::ReferenceEquals($update, $chosen)) { Write-AtlasTransitionEvidence "unexpected-offer, not installed: $(Format-PreparationOffer $update)" }
            }
            $why = if ($known.Count -gt 0) { 'a known KB' } else { "the release $WindowsTarget in its title" }
            Write-AtlasTransitionEvidence "offer, chosen by ${why}: $(Format-PreparationOffer $chosen)"
            return $chosen
        }
    }
}

# Waits without blocking a stop request, reporting every two seconds so the app
# sees the worker alive. The only clock the waits for an offer use, so tests
# stand in for it.
function Wait-PreparationSeconds([int]$Seconds) {
    for ($waited = 0; $waited -lt $Seconds; $waited += 2) {
        Assert-PreparationContinue
        Write-PreparationState running windows-search -Detail $script:PreparationSearchDetail
        Start-Sleep -Seconds 2
    }
}

# Until Windows Update shows the target in its policy state, at most
# $script:PreparationPolicyWaitSeconds.
function Wait-PreparationPolicyState {
    for ($waited = 0; ; $waited += 5) {
        if ((Get-PreparationPolicyState) -eq $WindowsTarget) { return $true }
        if ($waited -ge $script:PreparationPolicyWaitSeconds) { return $false }
        Wait-PreparationSeconds 5
    }
}

# Restarts Windows Update so it reads the target, unless it is installing
# something, then waits for the policy state to show the target.
function Update-PreparationTargetRead([string]$Why) {
    if ($script:PreparationServiceRestarts -ge $script:PreparationServiceRestartLimit) {
        Write-AtlasTransitionEvidence "$Why; Windows Update was already restarted $script:PreparationServiceRestarts times in this run"
        return
    }
    if (-not (Restart-PreparationUpdateService)) {
        Write-AtlasTransitionEvidence "$Why; Windows Update is busy, so it wasn't restarted"
        return
    }
    $script:PreparationServiceRestarts++
    $read = Wait-PreparationPolicyState
    Write-AtlasTransitionEvidence "$Why; restarted wuauserv, policy state now: target '$(Get-PreparationPolicyState)'$(if (-not $read) { " (not the target after $script:PreparationPolicyWaitSeconds seconds)" })"
}

# Windows Update reads the feature-update target only when it starts or scans,
# and offers the release some minutes after its policy state shows it. So: the
# policy state is checked before the first search; a first search that finds
# nothing is followed by one restart, then by searches with growing waits for up
# to $script:PreparationOfferWindowSeconds, stopping at the first offer. Each
# search asks Windows Update online, never only its cache (Invoke-PreparationSearch).
function Find-PreparationFeatureUpdate($Session) {
    $state = Get-PreparationPolicyState
    Write-AtlasTransitionEvidence "policy state before the search: target '$state'"
    $script:PreparationSearchDetail = @{ waiting = 'feature-offer' }
    try {
        if ($state -ne $WindowsTarget) { Update-PreparationTargetRead 'the policy state is not the target yet' }
        $update = Find-PreparationFeatureOffer $Session
        if ($null -eq $update -and -not $script:PreparationTargetReread) {
            $script:PreparationTargetReread = $true
            Update-PreparationTargetRead 'no offer on the first search'
            $waited = 0
            for ($attempt = 0; $null -eq $update -and $waited -lt $script:PreparationOfferWindowSeconds; $attempt++) {
                $backoff = @($script:PreparationOfferBackoff)
                $delay = [Math]::Min($backoff[[Math]::Min($attempt, $backoff.Count - 1)], $script:PreparationOfferWindowSeconds - $waited)
                Wait-PreparationSeconds $delay
                $waited += $delay
                Write-AtlasTransitionEvidence "searching again $($attempt + 1), $waited s after the first search"
                $update = Find-PreparationFeatureOffer $Session
            }
            if ($null -eq $update) { Write-AtlasTransitionEvidence "no offer within $waited s" }
        }
    }
    finally { $script:PreparationSearchDetail = @{} }
    $hidden = $false
    if ($null -eq $update) {
        try {
            $offers = @(Invoke-PreparationSearch $Session "IsInstalled=0 and IsHidden=1 and Type='Software' and CategoryIDs contains '$script:UpgradesCategory'" -IncludeSuperseded)
            $hidden = @($offers | Where-Object { (Test-PreparationKnownKb $_ $FeatureKb) -or (Test-PreparationTargetTitle $_) }).Count -gt 0
        }
        catch { Write-AtlasTransitionEvidence "hidden search failed: $($_.Exception.Message)" }
    }
    return [pscustomobject]@{ Update = $update; Hidden = $hidden }
}

function Write-PreparationJournal($Journal, [string]$Step, [string]$Detail = '') {
    Add-AtlasTransitionHistory $Journal $Step $Detail
    Write-AtlasWindowsTransition $Journal
}

# What the record calls a run that ended with $Detail: no offer yet is a wait,
# an outcome; anything else failed.
function Get-PreparationEndStep([hashtable]$Detail) {
    if ($Detail.ContainsKey('reason') -and $Detail.reason -in @('feature-not-offered', 'feature-prerequisite')) { return 'outcome' }
    return 'failed'
}

# How updates.log records the end of a run that stopped with $Detail: an outcome
# such as no offer yet is one line, and a failure keeps its error record and
# stack trace.
function Format-PreparationStop($Record, [hashtable]$Detail) {
    if ((Get-PreparationEndStep $Detail) -eq 'outcome') { return "Outcome ($($Detail['reason'])): $($Detail.failureMessage)" }
    return ($Record | Out-String)
}

# How a run ended, in the open record too, so a report shows it after the job
# folder is gone. A record that cannot be read or written is left as it is.
function Write-PreparationTransitionOutcome([string]$Step, [string]$Detail = '') {
    try {
        $journal = Read-AtlasWindowsTransition
        if ($null -ne $journal) { Write-PreparationJournal $journal $Step $Detail }
        else { Write-AtlasTransitionEvidence "$Step $Detail" }
    }
    catch { Write-AtlasTransitionEvidence "$Step $Detail (record not updated: $($_.Exception.Message))" }
}

# Why Windows Update offers nothing, from the most specific cause to the least.
# A cause Atlas itself could fix would be told apart here, before the general
# "not offered yet".
function Resolve-PreparationNoOffer($Journal, [bool]$Hidden) {
    if (Test-PreparationRestart) { return 'reboot' }
    $since = [DateTime]::Parse([string]$Journal.createdAt, [Globalization.CultureInfo]::InvariantCulture, [Globalization.DateTimeStyles]::AdjustToUniversal)
    $installed = @(Get-PreparationFeatureHistory | Where-Object { $_.ResultCode -eq $script:UpdateSucceeded -and $_.Date -ge $since })
    if ($installed.Count -gt 0) {
        # Windows installed it on its own after the new target.
        Set-PreparationInstalled $Journal "history: $($installed[0].Title)"
        $script:PreparationRestartReasons = @('feature-update')
        return 'reboot'
    }
    if ($Hidden) { throw (New-AtlasTransitionFailure "Windows Update has the update to $WindowsTarget hidden on this PC." 'feature-hidden') }
    $version = Get-PreparationWindowsVersion
    if ($MinimumRevision -gt 0 -and $version.Ubr -lt $MinimumRevision) {
        throw (New-AtlasTransitionFailure "Windows $($version.Build).$($version.Ubr) is below $MinimumRevision, which the update to $WindowsTarget needs, and Windows Update offers nothing newer." 'feature-prerequisite')
    }
    $gap = @(Get-PreparationHardwareGap)
    if ($gap.Count -gt 0) {
        throw (New-AtlasTransitionFailure "Windows Update offers no update to $WindowsTarget, and this PC lacks: $($gap -join ', ')." 'feature-hardware' @{ hardware = $gap -join ',' })
    }
    throw (New-AtlasTransitionFailure "Windows Update does not offer $WindowsTarget to this PC yet." 'feature-not-offered')
}

function Set-PreparationInstalled($Journal, [string]$Detail, $Update = $null) {
    $Journal.phase = 'installed'
    $installed = [pscustomobject]@{ boot = Get-PreparationBootId; detail = $Detail }
    if ($null -eq $Journal.PSObject.Properties['installed']) { $Journal | Add-Member -NotePropertyName installed -NotePropertyValue $null }
    $Journal.installed = $installed
    if ($null -ne $Update) {
        # Which update it was, so the commit and the history find it again.
        $title = ([string]$Update.Title) -replace '[\x00-\x1f\x7f]', ' '
        $offer = [pscustomobject][ordered]@{
            kb = (@(Get-PreparationUpdateKb $Update) | Where-Object { $_ -match '^\d{7}$' }) -join ','
            updateId = [string]$Update.Identity.UpdateID
            revision = if ($null -ne $Update.Identity.PSObject.Properties['RevisionNumber']) { [int]$Update.Identity.RevisionNumber } else { 0 }
            title = $title.Substring(0, [Math]::Min($title.Length, 200))
        }
        $Journal | Add-Member -NotePropertyName offer -NotePropertyValue $offer -Force
    }
    Write-PreparationJournal $Journal 'installed' $Detail
}

# Downloads and installs the enablement package on its own. Its licence is
# accepted only when the user accepted it in Atlas. Returns 'installed',
# 'reboot' (Windows wants a restart first) or 'retry' (after the first failure).
function Install-PreparationFeatureUpdate($Session, $Update, $Journal, [bool]$MayRetry) {
    if (-not $Update.EulaAccepted) {
        if (-not $AcceptLicense) { throw (New-AtlasTransitionFailure "The licence terms for Windows $WindowsTarget have not been accepted." 'feature-terms') }
        $Update.AcceptEula()
        Write-AtlasTransitionEvidence "accepted the licence terms for $WindowsTarget, as the user chose"
    }
    $updates = New-Object -ComObject Microsoft.Update.UpdateColl
    [void]$updates.Add($Update)
    $label = "'$($Update.Title)' KB=$((@(Get-PreparationUpdateKb $Update)) -join ',')"
    $failure = $null
    Assert-PreparationContinue
    Write-AtlasTransitionEvidence "free space before the update: $(Get-AtlasTransitionFreeSpace) bytes"
    Write-PreparationState running windows-download 0 1
    $downloader = $Session.CreateUpdateDownloader()
    $downloader.Updates = $updates
    $downloaded = Invoke-PreparationWindowsOperation $downloader $updates Download
    $item = $downloaded.GetUpdateResult(0)
    Write-AtlasTransitionEvidence "download ${label}: result=$($downloaded.ResultCode) HRESULT=0x$('{0:X8}' -f [int]$item.HResult)"
    if ([int]$downloaded.ResultCode -ne $script:UpdateSucceeded) { $failure = [int]$item.HResult }
    else {
        Assert-PreparationContinue
        Write-PreparationState running windows-install 0 1
        $installer = $Session.CreateUpdateInstaller()
        $installer.Updates = $updates
        $installer.ForceQuiet = $true
        $installer.AllowSourcePrompts = $false
        if ($installer.RebootRequiredBeforeInstallation) {
            Write-AtlasTransitionEvidence 'Windows needs a restart before it installs the update'
            $script:PreparationRestartReasons = @('windows-update')
            return 'reboot'
        }
        $installed = Invoke-PreparationWindowsOperation $installer $updates Install
        $item = $installed.GetUpdateResult(0)
        Write-AtlasTransitionEvidence "install ${label}: result=$($installed.ResultCode) HRESULT=0x$('{0:X8}' -f [int]$item.HResult) restart=$($installed.RebootRequired)"
        # Whether Windows moved is decided after the restart, by the build it
        # starts. Here, any result that leaves work for a restart is enough.
        if ([int]$installed.ResultCode -in @($script:UpdateSucceeded, 3) -or $installed.RebootRequired) {
            Set-PreparationInstalled $Journal "update=$($Update.Identity.UpdateID) result=$($installed.ResultCode)" $Update
            return 'installed'
        }
        $failure = [int]$item.HResult
        if ($failure -eq 0) { $failure = [int]$installed.HResult }
    }
    if ($script:UpdateAccessCodes -contains $failure) {
        # A Windows Update launcher from an earlier Atlas can turn it off again.
        if ($MayRetry) {
            Write-AtlasTransitionEvidence 'Windows Update was turned off again; turning it on once more'
            Update-AtlasTransitionLiftSet $Journal
            Invoke-AtlasWindowsUpdateLift $Journal
            return 'retry'
        }
        $settings = @(Get-AtlasWindowsUpdateBlocker | ForEach-Object { $_.Id.Split('.')[-1] })
        $setting = if ($settings.Count -gt 0) { $settings -join ', ' } else { 'Windows Update' }
        throw (New-AtlasTransitionFailure "Windows Update was turned off again while it installed $label." 'feature-blocked' @{ setting = $setting; errorCode = '0x{0:X8}' -f $failure })
    }
    if ($MayRetry) { return 'retry' }
    $detail = @{}
    if ($failure -ne 0) { $detail.errorCode = '0x{0:X8}' -f $failure }
    throw (New-AtlasTransitionFailure "Windows could not install $label." 'feature-failed' $detail)
}

# How Windows moved, decided once on the target build and kept in the record:
# switched on in place (the Atlas components are all there), or rebuilt by Setup,
# after which the Atlas install puts Atlas back with the recorded choices. Atlas
# components gone without any sign of Setup is not explained, and stops.
function Test-PreparationRebuild($Journal) {
    if ($null -ne $Journal.PSObject.Properties['rebuild'] -and $null -ne $Journal.rebuild) {
        if ($Journal.rebuild.rebuilt) { return }
        $present = @(Get-AtlasInstalledAtlasPackage)
        $missing = @(@($Journal.atlasPackages) | Where-Object { $present -notcontains $_ })
        if ($missing.Count -eq 0) { return }
    }
    $since = [DateTime]::Parse([string]$Journal.createdAt, [Globalization.CultureInfo]::InvariantCulture, [Globalization.DateTimeStyles]::AdjustToUniversal)
    $present = @(Get-AtlasInstalledAtlasPackage)
    $facts = Get-AtlasTransitionRebuildFact $since
    $rebuild = Resolve-AtlasTransitionRebuild $Journal $facts $present
    Write-AtlasTransitionEvidence "after the move: Windows.old populated $($facts.WindowsOld), Setup folder $($facts.SetupFolder), Setup log written since the record $($facts.PantherWritten), Atlas files $($facts.AtlasModules), Atlas packages $($present -join ',')"
    $path = if ($rebuild.rebuilt) { 'Setup rebuilt Windows' } elseif ($rebuild.setup) { 'Setup ran and Atlas''s components are all there' } else { 'switched on in place, Atlas''s components are all there' }
    if ($rebuild.lost -and -not $rebuild.setup) { $path = 'Atlas components are gone without a sign of Setup' }
    $Journal | Add-Member -NotePropertyName rebuild -NotePropertyValue ([pscustomobject][ordered]@{
            rebuilt = [bool]$rebuild.rebuilt; signals = @($rebuild.signals); checkedAt = $rebuild.checkedAt }) -Force
    Write-PreparationJournal $Journal $(if ($rebuild.rebuilt) { 'rebuilt' } else { 'moved' }) "$path; signals: $(@($rebuild.signals) -join ',')"
    if ($rebuild.lost -and -not $rebuild.setup) {
        throw (New-AtlasTransitionFailure "Atlas packages are missing after the update: $(@($rebuild.missing) -join ', ')." 'feature-components-lost')
    }
}

# On the target build: the move happened, by Atlas or by Windows.
function Complete-PreparationTransitionOnTarget($Journal) {
    if ($null -eq $Journal) { return (Invoke-PreparationAccess) }
    if ($Journal.kind -eq 'transition') {
        Test-PreparationRebuild $Journal
        if ($Journal.phase -ne 'on-target') {
            $Journal.phase = 'on-target'
            $version = Get-PreparationWindowsVersion
            Write-PreparationJournal $Journal 'on-target' "build=$($version.Build).$($version.Ubr) $($version.DisplayVersion)"
        }
    }
    Update-AtlasTransitionLiftSet $Journal
    Invoke-AtlasWindowsUpdateLift $Journal
    return (Invoke-PreparationUpdates)
}

# Still on the source build after the package was installed: the restart is
# still owed, Windows needs one more with Atlas's commit, or the update rolled back.
function Resolve-PreparationPendingMove($Journal) {
    $boot = Get-PreparationBootId
    $installedBoot = if ($null -ne $Journal.installed -and $null -ne $Journal.installed.PSObject.Properties['boot']) { [string]$Journal.installed.boot } else { '' }
    if ($boot -eq $installedBoot -or ($Journal.commitBoot -and [string]$Journal.commitBoot -eq $boot)) {
        Write-AtlasTransitionEvidence 'the update is installed and waits for a restart'
        $script:PreparationRestartReasons = @('feature-update')
        return 'reboot'
    }
    if (-not $Journal.commitBoot -and -not $Journal.commitRetried) {
        # Restarted from Start without Atlas's commit: one more restart, through Atlas.
        $Journal.commitRetried = $true
        Write-PreparationJournal $Journal 'commit-retry'
        $script:PreparationRestartReasons = @('feature-commit')
        return 'reboot'
    }
    $offerId = if ($null -ne $Journal.PSObject.Properties['offer'] -and $null -ne $Journal.offer) { [string]$Journal.offer.updateId } else { '' }
    $failed = @(Get-PreparationFeatureHistory $offerId | Where-Object { $_.ResultCode -ne $script:UpdateSucceeded } | Sort-Object Date -Descending)
    $code = if ($failed.Count -gt 0 -and $failed[0].HResult -ne 0) { '0x{0:X8}' -f $failed[0].HResult } else { '' }
    Write-PreparationJournal $Journal 'rolled-back' $code
    $detail = @{}
    if ($code) { $detail.errorCode = $code }
    throw (New-AtlasTransitionFailure "Windows went back to its earlier version after the restart." 'feature-rolled-back' $detail)
}

# Moves Windows to -WindowsTarget. Every run decides from the machine; the journal
# holds only the original settings and a diagnostic phase.
function Invoke-PreparationTransition {
    $journal = Read-AtlasWindowsTransition
    $version = Get-PreparationWindowsVersion
    Write-AtlasTransitionEvidence "transition run: target $WindowsTarget ($TargetBuild, known KB $FeatureKb) on $($version.Build).$($version.Ubr) $($version.DisplayVersion) $($version.EditionId); record: $(if ($journal) { "$($journal.kind) $($journal.phase)" } else { 'none' })"
    if ($version.Build -eq $TargetBuild) { return (Complete-PreparationTransitionOnTarget $journal) }
    if (@(Get-PreparationSourceBuild) -notcontains $version.Build) {
        throw (New-AtlasTransitionFailure "Windows build $($version.Build) is neither a source nor the target of this update." 'feature-build')
    }
    if ($null -ne $journal -and $journal.kind -eq 'transition' -and $journal.phase -eq 'installed') {
        return (Resolve-PreparationPendingMove $journal)
    }
    # Before a move starts, also after plain updates left their record open.
    if ($null -eq $journal -or $journal.kind -eq 'access') {
        if (Test-PreparationRestart) { return 'reboot' }
        # Nothing changes before Windows Update can be reached.
        if (-not (Test-PreparationNetwork)) { throw (New-Object System.Net.NetworkInformation.NetworkInformationException) }
        Test-AtlasWindowsTransitionPreflight
    }
    $source = [pscustomobject][ordered]@{ build = $version.Build; ubr = $version.Ubr; displayVersion = $version.DisplayVersion; editionId = $version.EditionId }
    $target = [pscustomobject][ordered]@{ release = $WindowsTarget; build = $TargetBuild; kb = $FeatureKb }
    $packages = @(Get-AtlasInstalledAtlasPackage)
    # Only a first record reads the install: on a resume the PC may already be rebuilt.
    $carry = if ($null -eq $journal -or $journal.kind -eq 'access') { Get-AtlasTransitionCarry $packages }
    $journal = Save-AtlasWindowsTransitionSnapshot -Kind transition -Source $source -Target $target `
        -UserSid ([Security.Principal.WindowsIdentity]::GetCurrent().User.Value) -AtlasPackages $packages -Carry $carry
    Update-AtlasTransitionLiftSet $journal
    Invoke-AtlasWindowsUpdateLift $journal
    $recheck = $OfferOnly -and $journal.phase -eq 'targeted'
    if ($recheck) {
        Write-AtlasTransitionEvidence 'recheck: only looking for the offer again'
        $script:PreparationTargetReread = $true
    }
    # Monthly updates first, with the target still unset, so Windows itself is
    # not told to move while they install.
    elseif ((Invoke-PreparationWindows | Select-Object -Last 1) -eq 'reboot') { return 'reboot' }
    Assert-PreparationContinue
    $before = Get-AtlasTransitionValue 'SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate' 'TargetReleaseVersionInfo'
    Set-AtlasFeatureUpdateTarget -Release $WindowsTarget
    Write-AtlasTransitionEvidence "set the feature-update target: $(Format-AtlasTransitionValue $before) -> $WindowsTarget"
    if ($journal.phase -eq 'lifted') {
        $journal.phase = 'targeted'
        Write-PreparationJournal $journal 'targeted' $WindowsTarget
    }
    Write-AtlasTransitionEvidence "Windows Update policy state: target '$(Get-PreparationPolicyState)'"
    if (-not (Test-PreparationNetwork)) { throw (New-Object System.Net.NetworkInformation.NetworkInformationException) }
    $session = New-Object -ComObject Microsoft.Update.Session
    $session.ClientApplicationID = 'Atlas preparation'
    for ($attempt = 1; $attempt -le 2; $attempt++) {
        Assert-PreparationContinue
        Write-PreparationState running windows-search
        try { $offer = Find-PreparationFeatureUpdate $session }
        catch {
            $code = Get-PreparationHResult $_.Exception
            if ($script:UpdateAccessCodes -notcontains $code) { throw }
            # Turned off again between turning it on and searching.
            if ($attempt -lt 2) {
                Write-AtlasTransitionEvidence ('search refused with 0x{0:X8}; turning Windows Update on once more' -f $code)
                Update-AtlasTransitionLiftSet $journal
                Invoke-AtlasWindowsUpdateLift $journal
                continue
            }
            $settings = @(Get-AtlasWindowsUpdateBlocker | ForEach-Object { $_.Id.Split('.')[-1] })
            $setting = if ($settings.Count -gt 0) { $settings -join ', ' } else { 'Windows Update' }
            throw (New-AtlasTransitionFailure 'Windows Update refused the search.' 'feature-blocked' @{ setting = $setting; errorCode = '0x{0:X8}' -f $code })
        }
        if ($null -eq $offer.Update) { return (Resolve-PreparationNoOffer $journal $offer.Hidden) }
        $result = Install-PreparationFeatureUpdate $session $offer.Update $journal ($attempt -lt 2)
        if ($result -eq 'reboot') { return 'reboot' }
        if ($result -eq 'installed') {
            $script:PreparationRestartReasons = @('feature-update')
            return 'reboot'
        }
    }
    throw (New-AtlasTransitionFailure "Windows could not install $WindowsTarget." 'feature-failed')
}

# Plain updates on a PC whose Windows Update is off, paused or delayed: the same
# record and restore, without moving Windows.
function Invoke-PreparationAccess {
    $journal = Read-AtlasWindowsTransition
    if ($null -eq $journal) {
        $blockers = @(Get-AtlasWindowsUpdateBlocker)
        if ($blockers.Count -eq 0) { return (Invoke-PreparationUpdates) }
        Write-AtlasTransitionEvidence "Windows Update is held back by: $(@($blockers.Id) -join ', ')"
        if (Test-PreparationRestart) { return 'reboot' }
        if (-not (Test-PreparationNetwork)) { throw (New-Object System.Net.NetworkInformation.NetworkInformationException) }
        Test-AtlasWindowsUpdateManaged
        $version = Get-PreparationWindowsVersion
        $source = [pscustomobject][ordered]@{ build = $version.Build; ubr = $version.Ubr; displayVersion = $version.DisplayVersion; editionId = $version.EditionId }
        $journal = Save-AtlasWindowsTransitionSnapshot -Kind access -Source $source -Target $null `
            -UserSid ([Security.Principal.WindowsIdentity]::GetCurrent().User.Value) -AtlasPackages @()
    }
    Update-AtlasTransitionLiftSet $journal
    Invoke-AtlasWindowsUpdateLift $journal
    return (Invoke-PreparationUpdates)
}

# Atlas's commit of a pending feature update, once per boot, just before Atlas
# restarts Windows. Calling it twice before one restart can fail the update. A
# commit that fails is logged and the restart goes ahead: the build Windows starts
# decides whether it moved.
function Invoke-PreparationCommit {
    $journal = Read-AtlasWindowsTransition
    if ($null -eq $journal -or $journal.kind -ne 'transition' -or $journal.phase -ne 'installed') {
        Write-AtlasTransitionEvidence 'commit: no installed update waits for a restart'
        return
    }
    $boot = Get-PreparationBootId
    if ([string]$journal.commitBoot -eq $boot) {
        Write-AtlasTransitionEvidence 'commit: already done in this boot'
        return
    }
    $offerId = if ($null -ne $journal.PSObject.Properties['offer'] -and $null -ne $journal.offer) { [string]$journal.offer.updateId } else { '' }
    $result = 'committed'
    try { Invoke-PreparationCommitCall $offerId }
    catch {
        $result = 'commit failed 0x{0:X8} ({1}); restarting anyway' -f (Get-PreparationHResult $_.Exception), $_.Exception.Message
    }
    $journal.commitBoot = $boot
    Write-PreparationJournal $journal 'commit' "$boot $result"
}

# Puts back the Windows Update settings an unfinished update changed. Never while
# an Atlas install is unfinished: its own closing step does it then.
function Invoke-PreparationRestore {
    if ([IO.File]::Exists([IO.Path]::Combine($env:WINDIR, 'AtlasOS\Install\active.json'))) {
        throw (New-AtlasTransitionFailure 'An Atlas install is unfinished; its closing step puts the settings back.' 'feature-install-active')
    }
    $journal = Read-AtlasWindowsTransition
    if ($null -eq $journal) { return }
    # After Windows rebuilt itself, the install needs the record to put Atlas back,
    # and its own last step puts the settings back then.
    if ($null -ne (Get-AtlasWindowsTransitionRebase)) {
        throw (New-AtlasTransitionFailure 'Windows reinstalled itself during the update; the Atlas install puts the settings back when it puts Atlas back.' 'feature-install-active')
    }
    $version = Get-PreparationWindowsVersion
    $boot = Get-PreparationBootId
    $pending = $journal.phase -eq 'installed' -and $null -ne $journal.installed -and
        ([string]$journal.installed.boot -eq $boot -or [string]$journal.commitBoot -eq $boot)
    $outcome = if (($journal.kind -eq 'transition' -and $version.Build -eq [int]$journal.target.build) -or $pending) { 'Moved' } else { 'Abandoned' }
    Write-AtlasTransitionEvidence "put back requested on $($version.Build).$($version.Ubr): $outcome"
    [void](Restore-AtlasWindowsTransition -Outcome $outcome)
}

if ($FunctionsOnly) { return }
$mutex = $null
$owned = $false
$transitionRun = $false
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
    $transitionRun = $WindowsTarget -or $OpenWindowsUpdate -or $CommitFeatureUpdate -or $RestoreWindowsUpdate
    if ($transitionRun) {
        # Beside the job folders, so it outlives the ones Atlas clears away.
        $script:AtlasTransitionEvidencePath = Join-Path (Split-Path -Parent $JobPath) 'windows-transition.log'
        Write-AtlasTransitionEvidence "worker $(Split-Path -Leaf $JobPath): $(@($PSBoundParameters.Keys | Where-Object { $_ -notin @('JobPath', 'PersistentCancellation') } | ForEach-Object { "-$_ $($PSBoundParameters[$_])" }) -join ' ')"
    }
    if ($CommitFeatureUpdate) {
        Invoke-PreparationCommit
        Write-PreparationState complete verify
        exit 0
    }
    if ($RestoreWindowsUpdate) {
        Invoke-PreparationRestore
        Write-PreparationState complete verify
        exit 0
    }
    Set-PreparationDriver
    $outcome = if ($WindowsTarget) { Invoke-PreparationTransition }
    elseif ($OpenWindowsUpdate) { Invoke-PreparationAccess }
    else { Invoke-PreparationUpdates }
    if (($outcome | Select-Object -Last 1) -eq 'reboot') {
        if ($transitionRun) { Write-PreparationTransitionOutcome 'restart' ($script:PreparationRestartReasons -join ',') }
        # What the Store stage did before the restart, so the app can still say so.
        $detail = Get-PreparationOutcomeDetail
        $detail.restartReasons = @($script:PreparationRestartReasons)
        Write-PreparationState reboot windows-install -Detail $detail
        exit 0
    }
    Write-PreparationState complete verify -Detail (Get-PreparationOutcomeDetail)
}
catch [System.Net.NetworkInformation.NetworkInformationException] {
    if ($transitionRun) { Write-PreparationTransitionOutcome 'network' $script:PreparationNetworkReason }
    Write-PreparationState network verify -Detail @{ networkReason = $script:PreparationNetworkReason }
}
catch [OperationCanceledException] {
    if ($transitionRun) { Write-PreparationTransitionOutcome 'stopped' }
    Write-PreparationState cancelled verify
}
catch {
    $failureDetail = Get-PreparationFailureDetail $_.Exception
    Format-PreparationStop $_ $failureDetail | Add-Content -LiteralPath (Join-Path $JobPath 'updates.log')
    if ($transitionRun) {
        Write-PreparationTransitionOutcome (Get-PreparationEndStep $failureDetail) ("reason=$($failureDetail['reason']) code=$($failureDetail['errorCode']) $($failureDetail.failureMessage)")
    }
    Write-PreparationState failed $script:PreparationStage -Detail $failureDetail
    exit 1
}
finally {
    if ($owned) { $mutex.ReleaseMutex() }
    if ($null -ne $mutex) { $mutex.Dispose() }
}
