<#
.SYNOPSIS
    Brings Windows and Store apps up to date before Atlas changes Windows, and moves
    Windows to a newer release when asked.
.DESCRIPTION
    Atlas Manager runs this script elevated, as the signed-in user, from a protected job
    folder. The front door runs it with -VerifyOnly before an install starts. Progress
    and the outcome go to state.json in the job folder, and the log to updates.log.
    Windows Update and Store work is never killed; cancellation waits for the active
    operation.
.PARAMETER JobPath
    The job folder, which holds state.json, updates.log, the cancel file and the
    DriverPolicy.reg a driver choice applies.
.PARAMETER FunctionsOnly
    Defines the functions and returns, so tests can load them.
.PARAMETER VerifyOnly
    Only checks that Windows and Microsoft Store have no updates left, and changes nothing.
.PARAMETER DriverMode
    preserve keeps the PC's driver policy; automatic and manual apply the job folder's
    DriverPolicy.reg.
.PARAMETER TargetBuild
    The build of the release -WindowsTarget names.
.PARAMETER SourceBuilds
    The builds the move may start from.
.PARAMETER CommitFeatureUpdate
    Commits an installed feature update once, just before Atlas restarts Windows.
.PARAMETER RestoreWindowsUpdate
    Puts back the Windows Update settings an unfinished update changed.
.NOTES
    Exit codes: 0 when the run ended as state.json records it (complete, restart needed,
    no network or stopped), 1 when it failed.
#>
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
# Local time, as event log queries take it: the AppX deployment events a failed
# Store item leads to are read from here on.
$script:PreparationStartedAt = [DateTime]::Now
$script:PreparationLastChange = 0L
$script:PreparationLastProgress = ''
# Whether Windows refused to replace state.json for a while, which the log notes once.
$script:PreparationStateHeld = $false
# Restart markers seen by the last Test-PreparationRestart, so the app can name one
# that survives a restart instead of asking for another.
$script:PreparationRestartReasons = @()
# Why the last Test-PreparationNetwork refused the connection; the app words each cause.
$script:PreparationNetworkReason = $null
$script:PreparationStage = 'verify'
# Windows Update values: OperationResultCode 2 = succeeded and 3 = succeeded with
# errors, UpdateType 2 = driver.
$script:UpdateSucceeded = 2
$script:UpdateSucceededWithErrors = 3
$script:DriverUpdate = 2
# The upgrades category, where Windows Update lists feature updates and
# enablement packages.
$script:UpgradesCategory = '3689BDC8-B205-4AF4-8D4A-A63924C5E9D5'
# ERROR_NO_MORE_ITEMS (0x80070103), which a driver's install ends with when the
# device already has a driver at least as good. Windows Update offers that driver
# again, and it fails the same way every time.
$script:DriverNotNeeded = -2147024637
# ERROR_SXS_COMPONENT_STORE_CORRUPT (0x80073712): an update failed because the
# component store, which Windows installs updates into, is damaged.
$script:ComponentStoreCorrupt = -2147010798
# A run reads the component store's health once and repairs it at most once:
# a repair can take half an hour.
$script:PreparationComponentChecked = $false
$script:PreparationComponentRepairRun = $false
# Searches that end with errors, and the wait before the second; each wait after
# it is that much longer.
$script:PreparationSearchAttempts = 3
$script:PreparationSearchRetrySeconds = 30
# WU_E_INSTALL_NOT_ALLOWED (0x80240016): another installation is in progress, or
# Windows waits for a restart it requires.
$script:InstallNotAllowed = -2145124330
# How long a run waits for another installation to finish before it tries again,
# at most, and how many such waits a run makes.
$script:PreparationBusyWaitSeconds = 600
$script:PreparationBusyWaits = 3
$script:PreparationBusyWaited = 0
# Microsoft Defender's security intelligence (KB2267602) and antimalware platform
# (KB4052623) updates. Windows Update can keep offering them once Atlas's
# NoDefender package has removed Defender, and they then fail with 0x80070643.
$script:DefenderUpdateKbs = @('2267602', '4052623')
# Defender updates this run has recorded as not needed, by id and revision.
$script:PreparationDefenderSkipped = @{}
# Searches per provider before giving up on one that keeps offering updates.
$script:PreparationPasses = 8
# Optional prerequisites that failed in this run, by id and revision; the passes
# after it install the monthly update instead (Find-PreparationPrerequisiteUpdate).
$script:PreparationOptionalFailed = @{}
# What the worker's reports say while it searches: set while it waits for
# Windows Update to offer a new release, so the app words the wait as one.
$script:PreparationSearchDetail = @{}
# Updates Get ready no longer waits for (offered again after they installed, or
# drivers the device doesn't need), by the registry value below.
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
    $code = if ($null -ne $ErrorCode) { $ErrorCode.HResult } else { 0 }
    # E_ABORT: something interrupted the Store's work on the item, which a later
    # try gets past. A Store that keeps doing it hasn't finished, rather than
    # being broken. One in a run where Windows already couldn't stage updates
    # (0x80070490) counts as that failure, which another try doesn't get past.
    $aborted = $code -eq $script:StoreAborted
    if ($aborted) {
        $staging = @(Get-PreparationStagingFailure)
        if ($staging.Count -gt 0) {
            $hidden = New-PreparationFailure "$message; Windows couldn't stage updates in this run (0x80070490, element not found): $(@($staging | ForEach-Object { $_.Name }) -join ', ')" $reason $script:StagingNotFound
            $hidden.Data['packageName'] = ($PackageFamilyName -split '_')[0].Split('.')[-1]
            return $hidden
        }
    }
    if ($aborted -and -not $reason) { $reason = 'store-timeout' }
    $failure = New-PreparationFailure $message $reason $code
    if ($aborted) { $failure.Data['storeTransient'] = 'retry' }
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

# Appends a line to this job's updates.log, always in UTF-8 like the driver policy
# import, so the file is UTF-8 whichever writes first. Windows PowerShell's
# Add-Content otherwise writes the ANSI code page, which exported diagnostics
# leave out.
function Write-PreparationLog([string]$Text) {
    Add-Content -LiteralPath (Join-Path $JobPath 'updates.log') -Value $Text -Encoding UTF8
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

# Why a pass leaves an offer out, for the log, or '' when it installs it.
# Feature upgrades can leave the builds supported by the chosen Atlas package;
# a move to another release finds its own. Optional previews are not a
# prerequisite for installing Atlas.
function Get-PreparationUpdateExclusion($Update) {
    if ($Update.BrowseOnly) { return 'an optional preview (browse-only), which installing Atlas doesn''t need' }
    if ($DriverMode -eq 'manual' -and [int]$Update.Type -eq $script:DriverUpdate) { return 'a driver, and drivers are left to the user (Install drivers myself)' }
    if (Test-PreparationUpgradeCategory $Update) { return 'a feature update, which only a move to another Windows release installs, through its own search' }
    return ''
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
    $bytes = (New-Object Text.UTF8Encoding($false)).GetBytes($json)
    $ownsTemporary = $false
    try {
        if ($PersistentCancellation) {
            $stream = New-Object IO.FileStream($temporary, [IO.FileMode]::CreateNew, [Security.AccessControl.FileSystemRights]::Write, [IO.FileShare]::None, 4096, [IO.FileOptions]::None, (Get-PreparationStateSecurity))
            $ownsTemporary = $true
            try {
                $stream.Write($bytes, 0, $bytes.Length)
                $stream.Flush($true)
            } finally { $stream.Dispose() }
        }
        else {
            [IO.File]::WriteAllBytes($temporary, $bytes)
            $ownsTemporary = $true
        }
        # A reader or a scanner can hold the previous report for a while; see
        # Install-AtlasTransitionFile in WindowsTransition.ps1. Progress while the
        # run goes on can wait for a later report: the earlier one stays whole and
        # names this process, and the output line below carries this one. How the
        # run ended can't wait, so that report gets longer. Atlas Manager and the
        # front door read only state.json, so when Windows still refuses to
        # replace it, the report is written over it in place. Only when that
        # fails too does the run fail with Windows's refusal, after the output
        # line has carried the report.
        $running = $Status -eq 'running'
        $refused = Install-AtlasTransitionFile $temporary $path $(if ($running) { 5 } else { 60 })
        if ($null -eq $refused) { $ownsTemporary = $false }
        elseif (-not $running) {
            $unwritten = Write-AtlasTransitionFileInPlace $path $bytes
            if ($null -ne $unwritten) {
                [Console]::WriteLine("ATLAS_PREP:$json")
                Write-PreparationLog ('state.json could not be replaced (0x{0:X8}: {1}) or written in place (0x{2:X8}: {3}).' -f $refused.HResult, ([string]$refused.Message).Trim(), $unwritten.HResult, ([string]$unwritten.Message).Trim())
                throw $refused
            }
            Write-PreparationLog ('state.json could not be replaced (0x{0:X8}: {1}); the report of how the run ended was written over it in place.' -f $refused.HResult, ([string]$refused.Message).Trim())
        }
        elseif (-not $script:PreparationStateHeld) {
            $script:PreparationStateHeld = $true
            Write-PreparationLog ('state.json could not be replaced (0x{0:X8}: {1}); it keeps the last report it took until a later one goes in.' -f $refused.HResult, ([string]$refused.Message).Trim())
        }
    } finally {
        if ($ownsTemporary) { [IO.File]::Delete($temporary) }
    }
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
    while ($true) {
        try {
            $job = if ($Kind -eq 'Download') { $Provider.BeginDownload($callback, $callback, $null) }
                   else { $Provider.BeginInstall($callback, $callback, $null) }
            break
        }
        catch {
            # Another installation holds Windows Update: wait for it, then start again.
            if ((Get-PreparationHResult $_.Exception) -ne $script:InstallNotAllowed -or -not (Wait-PreparationInstallerIdle $stage)) { throw }
        }
    }
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
# the provider's HRESULT and the revision-independent id a new search reuses. An
# install can fail without a code of its own; Windows Update's history then
# gives the code of that attempt.
function Get-PreparationFailedUpdate($Result, $Updates, [string]$Label) {
    for ($index = 0; $index -lt $Updates.Count; $index++) {
        $item = $Result.GetUpdateResult($index)
        $update = $Updates.Item($index)
        $code = [int]$item.HResult
        $history = ''
        if ($Label -eq 'result' -and [int]$item.ResultCode -ne $script:UpdateSucceeded -and $code -eq 0) {
            $code = Get-PreparationHistoryCode ([string]$update.Identity.UpdateID)
            $history = ', update history: 0x{0:X8}' -f $code
        }
        Write-PreparationLog "$($update.Title): $Label=$($item.ResultCode), HRESULT=$($item.HResult)$history"
        if ([int]$item.ResultCode -ne $script:UpdateSucceeded) {
            [pscustomobject]@{ Id = [string]$update.Identity.UpdateID; Update = $update; HResult = $code }
        }
    }
}

# The code Windows Update's history gives the newest attempt at an update, or 0.
function Get-PreparationHistoryCode([string]$UpdateId) {
    if (-not $UpdateId) { return 0 }
    try {
        $searcher = (New-Object -ComObject Microsoft.Update.Session).CreateUpdateSearcher()
        $count = [Math]::Min([int]$searcher.GetTotalHistoryCount(), 50)
        if ($count -le 0) { return 0 }
        $newest = $null
        foreach ($entry in $searcher.QueryHistory(0, $count)) {
            $id = try { [string]$entry.UpdateIdentity.UpdateID } catch { '' }
            if ($id -eq $UpdateId -and ($null -eq $newest -or [DateTime]$entry.Date -gt [DateTime]$newest.Date)) { $newest = $entry }
        }
        if ($null -ne $newest) { return [int]$newest.HResult }
    }
    catch { Write-PreparationLog "Windows Update's history couldn't be read: $($_.Exception.Message)" }
    return 0
}

# Waits for Windows Update's installer to finish another installation before what
# met it (0x80240016) is tried again: at least 30 seconds, then while the
# installer reports it is busy, up to $script:PreparationBusyWaitSeconds. Returns
# $false, without waiting, once a run has waited $script:PreparationBusyWaits
# times, so a refusal that waiting doesn't clear is reported.
function Wait-PreparationInstallerIdle([string]$Stage) {
    if ($script:PreparationBusyWaited -ge $script:PreparationBusyWaits) { return $false }
    $script:PreparationBusyWaited++
    Write-PreparationLog "Windows Update is busy with another installation (0x80240016); waiting for it, then trying again ($script:PreparationBusyWaited of $script:PreparationBusyWaits)."
    for ($waited = 0; $waited -lt $script:PreparationBusyWaitSeconds; $waited += 2) {
        Assert-PreparationContinue
        Write-PreparationState running $Stage
        if ($waited -ge 30 -and -not (Test-PreparationInstallerBusy)) { break }
        Start-Sleep -Seconds 2
    }
    return $true
}

function Test-PreparationInstallerBusy {
    try { return [bool](New-Object -ComObject Microsoft.Update.Installer).IsBusy }
    catch { return $false }
}

# The updates the last restart was for: those an install pass left failed, or for
# Windows to finish at the restart, with the start of Windows the pass ran in.
# Kept under HKLM beside the record of updates no longer waited for.
function Get-PreparationRestartRecordText {
    $value = Get-AtlasTransitionValue $script:PreparationReofferedRoot 'RestartFor'
    if ($value.Present -and $value.Kind -eq 'String') { return [string]$value.Data }
    return ''
}

function Set-PreparationRestartRecordText([string]$Text) {
    if ($Text) { Set-AtlasTransitionValue $script:PreparationReofferedRoot 'RestartFor' 'String' $Text }
    else { Remove-AtlasTransitionValue $script:PreparationReofferedRoot 'RestartFor' }
}

# The updates the last restart was for, by id and revision with their titles,
# once Windows has started again since. A record more than a day old belongs to
# an earlier preparation, and counts for nothing.
function Get-PreparationRestartedFor {
    $restarted = @{}
    try {
        $text = Get-PreparationRestartRecordText
        if (-not $text) { return $restarted }
        $record = $text | ConvertFrom-Json -ErrorAction Stop
        $at = [DateTime]::MinValue
        if (-not [DateTime]::TryParse([string]$record.at, [Globalization.CultureInfo]::InvariantCulture,
                [Globalization.DateTimeStyles]::AdjustToUniversal, [ref]$at) -or
            $at -lt [DateTime]::UtcNow.AddDays(-1) -or [string]$record.boot -eq (Get-PreparationBootId)) { return $restarted }
        foreach ($entry in @($record.updates)) {
            if ($null -ne $entry -and [string]$entry.key -match '^[^\x00-\x1f]{1,80}$') { $restarted[[string]$entry.key] = [string]$entry.title }
        }
    }
    catch { Write-PreparationLog "The record of what the last restart was for couldn't be read: $($_.Exception.Message)" }
    return $restarted
}

# Records the updates a restart is for, or clears the record with none.
function Save-PreparationRestartedFor($Updates) {
    try {
        $entries = @(foreach ($update in @($Updates | Where-Object { $null -ne $_ })) {
                $title = ([string]$update.Title) -replace '[\x00-\x1f]', ' '
                [pscustomobject][ordered]@{ key = Get-PreparationUpdateKey $update; title = $title.Substring(0, [Math]::Min($title.Length, 200)) }
            })
        if ($entries.Count -eq 0) { Set-PreparationRestartRecordText ''; return }
        $record = [pscustomobject][ordered]@{ boot = Get-PreparationBootId; at = [DateTime]::UtcNow.ToString('o'); updates = @($entries | Select-Object -First 50) }
        Set-PreparationRestartRecordText (ConvertTo-Json -InputObject $record -Depth 4 -Compress)
    }
    catch { Write-PreparationLog "What this restart is for couldn't be recorded: $($_.Exception.Message)" }
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
    Write-PreparationLog "Retrying $($Failed.Count) failed update(s) after a fresh search."
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
# install's own check reads the same record. A driver Windows Update fails with
# 0x80070103, because the device already has one at least as good, is recorded
# the same way.
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

# The updates the record says are no longer waited for. A Defender update recorded
# because Atlas removed Defender isn't among them: whether Defender is there now
# decides that each time (Test-PreparationDefenderRemoved).
function Get-PreparationReofferedKey {
    $keys = New-Object 'Collections.Generic.HashSet[string]'
    foreach ($entry in @(Read-PreparationReoffered)) {
        if ((Get-PreparationHandledWhy $entry) -eq 'defender-removed') { continue }
        [void]$keys.Add([string]$entry.key)
    }
    return , $keys
}

function Get-PreparationHandledWhy($Entry) {
    $why = $Entry.PSObject.Properties['why']
    if ($null -ne $why) { return [string]$why.Value }
    return ''
}

# Whether Atlas removed Microsoft Defender from this PC: its NoDefender package
# is installed, and Defender can't run, with no WinDefend service or no Defender
# engine (MsMpEng.exe) where Windows runs it from. Defender's own updates then have
# nothing to update. The package alone isn't enough: Defender's updates stay
# required wherever Defender could still run.
function Test-PreparationDefenderRemoved {
    if ((Get-AtlasTransitionDefenderPackageState) -cne 'Installed') { return $false }
    if (-not (Test-AtlasTransitionKey 'SYSTEM\CurrentControlSet\Services\WinDefend')) { return $true }
    return -not (Test-PreparationDefenderEngine)
}

# Whether a Defender engine is on this PC: in Program Files, as Windows installs
# it, or in a platform folder its updates add under ProgramData. A folder that
# can't be read counts as holding one.
function Test-PreparationDefenderEngine {
    if ([IO.File]::Exists([IO.Path]::Combine([Environment]::GetFolderPath('ProgramFiles'), 'Windows Defender\MsMpEng.exe'))) { return $true }
    $platform = [IO.Path]::Combine([Environment]::GetFolderPath('CommonApplicationData'), 'Microsoft\Windows Defender\Platform')
    try {
        if (-not [IO.Directory]::Exists($platform)) { return $false }
        foreach ($folder in [IO.Directory]::EnumerateDirectories($platform)) {
            if ([IO.File]::Exists([IO.Path]::Combine($folder, 'MsMpEng.exe'))) { return $true }
        }
        return $false
    }
    catch { return $true }
}

# A Defender update this PC has no Defender for: logged each time it's left out,
# and recorded once a run the way a driver that isn't needed is, outside the check
# before the install, which changes nothing.
function Add-PreparationDefenderNotNeeded($Update) {
    $line = "defender update not needed, not installed: '$($Update.Title)': Atlas removed Microsoft Defender from this PC (NoDefender package installed, Defender not there to update)"
    $key = Get-PreparationUpdateKey $Update
    if ($VerifyOnly -or $script:PreparationDefenderSkipped.ContainsKey($key)) {
        Write-PreparationLog $line
        return
    }
    $script:PreparationDefenderSkipped[$key] = $true
    Save-PreparationHandled $Update $line 'defender-removed'
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

# Logs why an update is no longer waited for, then records it. $Why names a
# record whose update the record alone doesn't decide; each such kind keeps only
# its newest entry for each KB, as these updates take a new id every few hours.
function Save-PreparationHandled($Update, [string]$Line, [string]$Why = '') {
    Write-PreparationLog $Line
    Write-AtlasTransitionEvidence $Line
    try {
        $title = [string]$Update.Title
        $key = Get-PreparationUpdateKey $Update
        $kb = @(Get-PreparationUpdateKb $Update) -join ','
        $entries = @(Read-PreparationReoffered | Where-Object {
                [string]$_.key -ne $key -and -not ($Why -and (Get-PreparationHandledWhy $_) -eq $Why -and [string]$_.PSObject.Properties['kb'].Value -eq $kb) })
        $entry = [ordered]@{ key = $key; kb = $kb; title = $title.Substring(0, [Math]::Min($title.Length, 200)); at = [DateTime]::UtcNow.ToString('o') }
        if ($Why) { $entry.why = $Why }
        $entries += [pscustomobject]$entry
        # The install's check skips only what's listed, so the list has room for more
        # than one run records. Entries lapse after 30 days.
        if ($entries.Count -gt 100) { $entries = $entries[($entries.Count - 100)..($entries.Count - 1)] }
        Write-PreparationReoffered $entries
    }
    catch { Write-PreparationLog "The update could not be recorded: $($_.Exception.Message)" }
}

function Add-PreparationReoffered($Update) {
    $title = [string]$Update.Title
    $offered = if ($title -match '\(Version ([0-9.]+)\)') { $Matches[1] } else { '' }
    $installed = Get-PreparationInstalledVersion $Update
    Save-PreparationHandled $Update "reoffered-after-success, not installed again: '$title' KB=$((@(Get-PreparationUpdateKb $Update)) -join ',') offered=$offered installed=$installed"
}

function Add-PreparationDriverNotNeeded($Update) {
    Save-PreparationHandled $Update "driver not needed, not installed again: '$($Update.Title)': Windows reports a driver at least as good is installed (0x80070103)"
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
            Write-PreparationLog $line
            Write-AtlasTransitionEvidence $line
            continue
        }
        $update
    }
}

function Write-PreparationComponentEvidence([string]$Text) {
    Write-PreparationLog "Component store: $Text"
    Write-AtlasTransitionEvidence "component store: $Text"
}

# Windows's own record of its component store: Healthy, Repairable or
# NonRepairable. Unknown when it can't be read, which is no evidence of damage.
function Get-PreparationComponentHealth {
    try { return [string](Get-AtlasTransitionImageHealth) }
    catch {
        Write-PreparationComponentEvidence ('its health could not be read (0x{0:X8}): {1}' -f $_.Exception.HResult, $_.Exception.Message)
        return 'Unknown'
    }
}

# Before a run's first search, damage Windows has already recorded is repaired,
# as updates fail on it. Not on a PC with Atlas packages: those alone make the
# store read as repairable, and a repair doesn't clear that (see "The component
# store and the Atlas packages" in docs/preparation.md). Damage Windows can't
# repair stops the run. Returns whether a repair ran.
function Repair-PreparationRecordedDamage {
    if ($script:PreparationComponentChecked) { return $false }
    $script:PreparationComponentChecked = $true
    $health = Get-PreparationComponentHealth
    if ($health -eq 'NonRepairable') {
        Write-PreparationComponentEvidence 'Windows records damage it can''t repair'
        throw (New-PreparationFailure 'Windows reports that its component store is damaged beyond repair.' 'component-store-unrepairable')
    }
    if ($health -ne 'Repairable') { return $false }
    $packages = @(Get-AtlasInstalledAtlasPackage)
    if ($packages.Count -gt 0) {
        Write-PreparationComponentEvidence "repairable, with Atlas packages installed ($($packages -join ', ')); left as it is"
        return $false
    }
    return (Invoke-PreparationComponentRepair 'Windows records damage to it')
}

# Repairs the store once a run; returns whether the repair ran. -Ahead is a
# repair before any update has failed on the store: when it fails, it doesn't
# use up the run's repair, which an update that does fail on it then gets.
function Invoke-PreparationComponentRepair([string]$Why, [switch]$Ahead) {
    if ($script:PreparationComponentRepairRun) { return $false }
    $script:PreparationComponentRepairRun = $true
    Write-PreparationComponentEvidence "$Why; repairing it with DISM RestoreHealth"
    Write-PreparationState running windows-repair
    try { $code = [int](Invoke-PreparationRestoreHealth) }
    catch {
        Write-PreparationComponentEvidence "the repair could not run: $($_.Exception.Message)"
        if ($Ahead) { $script:PreparationComponentRepairRun = $false }
        return $true
    }
    Write-PreparationComponentEvidence ('the repair ended with 0x{0:X8}; Windows now records it as {1}' -f $code, (Get-PreparationComponentHealth))
    # 3010: done, with a restart to finish it.
    if ($Ahead -and $code -notin @(0, 3010)) { $script:PreparationComponentRepairRun = $false }
    return $true
}

# DISM's RestoreHealth, which repairs the store from Windows Update. It reports
# no progress Atlas can read and, like Windows Update's own work, is never
# stopped: a stop waits for its end. Returns DISM's exit code.
function Invoke-PreparationRestoreHealth {
    $dism = [IO.Path]::Combine([Environment]::GetFolderPath('System'), 'Dism.exe')
    $process = Start-Process -FilePath $dism -ArgumentList '/Online /Cleanup-Image /RestoreHealth /NoRestart' -WindowStyle Hidden -PassThru
    # Holding the handle keeps the exit code, which is otherwise lost when the
    # process ends before it is read.
    $null = $process.Handle
    while (-not $process.WaitForExit(2000)) { Write-PreparationState running windows-repair }
    return $process.ExitCode
}

function Invoke-PreparationWindows {
    $retried = @{}
    # Updates this run installed successfully, and drivers it found the device
    # doesn't need, by id and revision.
    $succeeded = @{}
    $notNeeded = @{}
    # What the last restart was for, once Windows has started again since: an
    # update among them that fails again, or asks for yet another restart, is
    # reported instead of restarting once more.
    $restartedFor = Get-PreparationRestartedFor
    for ($pass = 0; $pass -lt $script:PreparationPasses; $pass++) {
        Assert-PreparationContinue
        if (Test-PreparationRestart) { return 'reboot' }
        if (-not (Test-PreparationNetwork)) { throw (New-Object System.Net.NetworkInformation.NetworkInformationException) }
        # The repair can leave a restart for Windows to finish it.
        if ($pass -eq 0 -and (Repair-PreparationRecordedDamage) -and (Test-PreparationRestart)) { return 'reboot' }
        Write-PreparationState running windows-search
        $session = New-Object -ComObject Microsoft.Update.Session
        $session.ClientApplicationID = 'Atlas preparation'
        $updates = New-Object -ComObject Microsoft.Update.UpdateColl
        $interactive = @()
        $required = @(Find-PreparationWindowsUpdate $session)
        $prerequisites = @(Find-PreparationPrerequisiteUpdate $session)
        $optional = @{}
        foreach ($update in $prerequisites) { $optional[(Get-PreparationUpdateKey $update)] = $true }
        foreach ($update in @(Select-PreparationNewestUpdate ($required + $prerequisites))) {
            $key = Get-PreparationUpdateKey $update
            if ($succeeded.ContainsKey($key)) {
                Add-PreparationReoffered $update
                continue
            }
            if ($notNeeded.ContainsKey($key)) { continue }
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
            if ($updates.Count -eq 0) {
                if ($restartedFor.Count -gt 0) { Save-PreparationRestartedFor @() }
                return 'complete'
            }
        }
        Assert-PreparationContinue
        Write-PreparationState running windows-download 0 $updates.Count
        $downloader = $session.CreateUpdateDownloader()
        $downloader.Updates = $updates
        $downloaded = Invoke-PreparationWindowsOperation $downloader $updates Download
        if ([int]$downloaded.ResultCode -ne $script:UpdateSucceeded) {
            $failed = @(Get-PreparationFailedUpdate $downloaded $updates 'download result')
            $optionalFailures = @(Select-PreparationOptionalFailure $failed $optional)
            $failed = @($failed | Where-Object { $optionalFailures -notcontains $_ })
            if ($failed.Count -eq 0 -and $optionalFailures.Count -gt 0) { continue }
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
        # What a restart would be for: what failed, and what Windows finishes then.
        $unfinished = @()
        for ($index = 0; $index -lt $updates.Count; $index++) {
            $result = $installed.GetUpdateResult($index)
            $update = $updates.Item($index)
            $key = Get-PreparationUpdateKey $update
            $restart = $result.PSObject.Properties['RebootRequired']
            $finishesAtRestart = if ($null -ne $restart) { [bool]$restart.Value } else { [bool]$installed.RebootRequired }
            if ([int]$result.ResultCode -eq $script:UpdateSucceeded) { $succeeded[$key] = $true }
            if (([int]$result.ResultCode -ne $script:UpdateSucceeded -or $finishesAtRestart) -and -not $optional.ContainsKey($key)) { $unfinished += $update }
        }
        $manual = @()
        $failed = @()
        $unneededDrivers = 0
        foreach ($entry in @(Get-PreparationFailedUpdate $installed $updates 'result')) {
            if ($entry.HResult -eq $script:DriverNotNeeded -and [int]$entry.Update.Type -eq $script:DriverUpdate) {
                $notNeeded[(Get-PreparationUpdateKey $entry.Update)] = $true
                Add-PreparationDriverNotNeeded $entry.Update
                $unneededDrivers++
                $unfinished = @($unfinished | Where-Object { -not [object]::ReferenceEquals($_, $entry.Update) })
            }
            elseif ($entry.Update.InstallationBehavior.CanRequestUserInput) { $manual += $entry.Update.Title }
            else { $failed += $entry }
        }
        $optionalFailures = @(Select-PreparationOptionalFailure $failed $optional -Installed)
        $failed = @($failed | Where-Object { $optionalFailures -notcontains $_ })
        # A restart Windows needs outranks a partial failure.
        $restartNeeded = [bool]$installed.RebootRequired
        if (-not $restartNeeded) { $restartNeeded = Test-PreparationRestart }
        # Without another restart, an update that met another installation or a
        # damaged store gets the wait or the repair below before it can count as
        # one the restart didn't finish.
        $handledHere = @{}
        if (-not $restartNeeded) {
            foreach ($entry in @($failed | Where-Object { $_.HResult -in @($script:InstallNotAllowed, $script:ComponentStoreCorrupt) })) {
                $handledHere[(Get-PreparationUpdateKey $entry.Update)] = $true
            }
        }
        $again = @($unfinished | Where-Object {
                $restartedFor.ContainsKey((Get-PreparationUpdateKey $_)) -and -not $handledHere.ContainsKey((Get-PreparationUpdateKey $_))
            })
        if ($again.Count -gt 0) {
            Save-PreparationRestartedFor @()
            $titles = @($again | ForEach-Object { [string]$_.Title }) -join '; '
            Write-PreparationLog "Not restarting again: Windows restarted for these updates, and they didn't finish: $titles"
            $failure = New-PreparationFailure "Windows couldn't finish these updates, even after restarting. Finish them in Windows Settings, then retry: $titles" 'manual-updates'
            $failure.Data['restartRepeated'] = $true
            throw $failure
        }
        if ($restartNeeded) {
            Save-PreparationRestartedFor $unfinished
            if ($installed.RebootRequired) { $script:PreparationRestartReasons = @('windows-update') }
            return 'reboot'
        }
        if ($manual.Count -gt 0) { throw (New-PreparationFailure "Windows could not finish these updates automatically. Finish them in Windows Settings, then retry: $($manual -join '; ')" 'manual-updates') }
        # A pass whose only failures were drivers the device doesn't need, or
        # optional prerequisites, is done; the next search leaves them out.
        if ([int]$installed.ResultCode -ne $script:UpdateSucceeded -and ($failed.Count -gt 0 -or ($unneededDrivers -eq 0 -and $optionalFailures.Count -eq 0))) {
            # Updates that failed on a damaged component store get another try
            # once it's repaired, even if they've had one.
            $damaged = @($failed | Where-Object { $_.HResult -eq $script:ComponentStoreCorrupt })
            if ($damaged.Count -gt 0 -and (Invoke-PreparationComponentRepair "$($damaged.Count) update(s) failed on it (0x80073712)")) {
                foreach ($entry in $damaged) { $retried.Remove($entry.Id) }
            }
            # So do updates that met another installation, once it's done.
            $busy = @($failed | Where-Object { $_.HResult -eq $script:InstallNotAllowed })
            if ($busy.Count -gt 0 -and (Wait-PreparationInstallerIdle windows-install)) {
                foreach ($entry in $busy) { $retried.Remove($entry.Id) }
            }
            Register-PreparationRetry $failed $installed $retried "Windows could not install every update: $($installed.ResultCode). See updates.log."
        }
    }
    throw (New-PreparationFailure "Windows still offers updates after $script:PreparationPasses passes. Resolve the remaining updates in Windows Settings." 'windows-passes')
}

# The optional prerequisites among $Failed. Each is logged and left out of the
# rest of the run, so the next pass installs the monthly update it replaced. An
# install that met another installation or a damaged store (-Installed) gets the
# wait or the repair first, as any update does, while the run has one left.
function Select-PreparationOptionalFailure($Failed, [hashtable]$Optional, [switch]$Installed) {
    foreach ($entry in @($Failed)) {
        $key = Get-PreparationUpdateKey $entry.Update
        if (-not $Optional.ContainsKey($key)) { continue }
        if ($Installed -and (($entry.HResult -eq $script:InstallNotAllowed -and $script:PreparationBusyWaited -lt $script:PreparationBusyWaits) -or
                ($entry.HResult -eq $script:ComponentStoreCorrupt -and -not $script:PreparationComponentRepairRun))) { continue }
        $script:PreparationOptionalFailed[$key] = $true
        $line = "Optional update '$($entry.Update.Title)' failed (0x{0:X8}); installing the monthly update it replaced instead." -f $entry.HResult
        Write-PreparationLog $line
        Write-AtlasTransitionEvidence $line
        $entry
    }
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

# The parts of a search that failed, from the warnings its result carries.
function Get-PreparationSearchWarning($Result) {
    $warnings = $Result.PSObject.Properties['Warnings']
    if ($null -eq $warnings -or $null -eq $warnings.Value) { return }
    foreach ($warning in @($warnings.Value)) {
        [pscustomobject]@{ HResult = [int]$warning.HResult; Context = [int]$warning.Context; Message = ([string]$warning.Message).Trim() }
    }
}

# Windows Update errors that pass on their own: the service was stopping
# (WU_E_SERVICE_STOP, 0x8024001E), it dropped the search as it restarted
# (0x80240069), as it can straight after a component store repair, its server
# couldn't be reached (WU_E_PT_ENDPOINT_UNREACHABLE, 0x80240438), or the server
# answered with an HTTP error (WU_E_PT_HTTP_STATUS_*, 0x80244010 to 0x8024401F),
# as a proxy can.
function Test-PreparationTransientUpdateError([int]$HResult) {
    return $HResult -in @(-2145124322, -2145124247, -2145123272) -or ($HResult -ge -2145107952 -and $HResult -le -2145107937)
}

# How long a search that failed waits, at most, for Windows Update to run again.
$script:PreparationServiceWaitSeconds = 120

function Get-PreparationUpdateServiceStatus { [string](Get-Service -Name wuauserv -ErrorAction Stop).Status }

function Start-PreparationUpdateService { Start-Service -Name wuauserv -ErrorAction Stop }

# Before a search runs again, Windows Update has to be running: one that is
# stopping, or stopped after it dropped the search, fails the next search the
# same way. A stopped service is started once, as any search would start it.
# One still not running after $script:PreparationServiceWaitSeconds is logged,
# and the search runs anyway: its own result is what the run reports.
function Wait-PreparationUpdateService {
    $started = $false
    for ($waited = 0; ; $waited += 2) {
        $status = try { Get-PreparationUpdateServiceStatus } catch { "unreadable ($($_.Exception.Message))" }
        if ($status -eq 'Running') { return $true }
        if ($waited -ge $script:PreparationServiceWaitSeconds) {
            Write-PreparationLog "Windows Update still reports $status after $waited seconds; searching again anyway."
            return $false
        }
        if ($status -eq 'Stopped' -and -not $started) {
            $started = $true
            try { Start-PreparationUpdateService }
            catch { Write-PreparationLog "Windows Update couldn't be started: $($_.Exception.Message)" }
        }
        Assert-PreparationContinue
        Write-PreparationState running windows-search -Detail $script:PreparationSearchDetail
        Start-Sleep -Seconds 2
    }
}

# A search that fails, or ends with errors, runs again after a wait that grows
# with each attempt. One that still fails with an error that passes on its own
# ends the run as windows-update-unreachable, which the app words.
function Invoke-PreparationSearch($Session, [string]$Criteria, [switch]$IncludeSuperseded) {
    for ($attempt = 1; ; $attempt++) {
        $searcher = New-PreparationSearcher $Session
        # A hidden update can be superseded by another hidden one; without this the
        # search for hidden updates can miss it.
        if ($IncludeSuperseded) { $searcher.IncludePotentiallySupersededUpdates = $true }
        $callback = New-PreparationCallback
        try {
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
        }
        catch {
            $failure = Get-PreparationHResult $_.Exception
            if (-not (Test-PreparationTransientUpdateError $failure)) { throw }
            $described = '0x{0:X8} {1}' -f $failure, ([string]$_.Exception.Message).Trim()
            Write-PreparationLog "Windows Update search failed on attempt $attempt of $script:PreparationSearchAttempts`: $described"
            Write-AtlasTransitionEvidence "search failed: $described"
            if ($attempt -ge $script:PreparationSearchAttempts) {
                throw (New-PreparationFailure "Windows Update couldn't be reached: $described" 'windows-update-unreachable' $failure)
            }
            Wait-PreparationSeconds ($script:PreparationSearchRetrySeconds * $attempt)
            [void](Wait-PreparationUpdateService)
            continue
        }
        Write-AtlasTransitionEvidence "search on $(Format-PreparationService $searcher): result $($found.ResultCode), $(@($found.Updates).Count) update(s) for $Criteria"
        $code = [int]$found.ResultCode
        if ($code -eq $script:UpdateSucceeded) { break }
        # Result 3 (succeeded with errors) means part of the search failed, so what it
        # found may be incomplete. Its warnings say which part; that is often a passing
        # service fault, so the search runs again before preparation stops.
        $warnings = @(Get-PreparationSearchWarning $found)
        $described = if ($warnings.Count) { ($warnings | ForEach-Object { '0x{0:X8} (context {1}) {2}' -f $_.HResult, $_.Context, $_.Message }) -join '; ' } else { 'no warnings given' }
        Write-PreparationLog "Windows Update search ended with result $code on attempt $attempt of $script:PreparationSearchAttempts`: $described"
        Write-AtlasTransitionEvidence "search warnings: $described"
        if ($code -ne $script:UpdateSucceededWithErrors -or $attempt -ge $script:PreparationSearchAttempts) {
            $hresult = if ($warnings.Count) { $warnings[0].HResult } else { 0 }
            $reason = if (@($warnings | Where-Object { Test-PreparationTransientUpdateError $_.HResult }).Count -gt 0) { 'windows-update-unreachable' } else { $null }
            throw (New-PreparationFailure "Windows update search failed: $code ($described)" $reason $hresult)
        }
        Wait-PreparationSeconds ($script:PreparationSearchRetrySeconds * $attempt)
    }
    foreach ($update in $found.Updates) { $update }
}

function Find-PreparationWindowsUpdate($Session) {
    $handled = Get-PreparationReofferedKey
    $defenderRemoved = $null
    foreach ($update in @(Invoke-PreparationSearch $Session "IsInstalled=0 and IsHidden=0 and BrowseOnly=0 and DeploymentAction='Installation'")) {
        $excluded = Get-PreparationUpdateExclusion $update
        if ($excluded) {
            Write-PreparationLog "Left '$($update.Title)': $excluded."
            continue
        }
        if (Test-PreparationKnownKb $update ($script:DefenderUpdateKbs -join ',')) {
            if ($null -eq $defenderRemoved) { $defenderRemoved = Test-PreparationDefenderRemoved }
            if ($defenderRemoved) {
                Add-PreparationDefenderNotNeeded $update
                continue
            }
        }
        if ($handled.Contains((Get-PreparationUpdateKey $update))) {
            Write-PreparationLog "Left '$($update.Title)': Windows offers it again, and an earlier pass recorded it as done."
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
        if ([string]$category.CategoryID -eq $script:UpgradesCategory) { return $true }
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

# Whether an update's title names a Windows release, as in "version 25H2", and
# not the target. Windows Update can offer another release's feature update
# under a KB number the target's is known by, and refuses to download it.
function Test-PreparationOtherReleaseTitle($Update, [string]$Release = $WindowsTarget) {
    if (-not $Release) { return $false }
    $property = $Update.PSObject.Properties['Title']
    $title = if ($null -ne $property) { [string]$property.Value } else { '' }
    return $title -match '(^|[^0-9A-Za-z])\d{2}H\d([^0-9A-Za-z]|$)' -and -not (Test-PreparationTargetTitle $Update $Release)
}

function Test-PreparationKnownKb($Update, [string]$List) {
    if (-not $List) { return $false }
    $known = @($List -split ',')
    return @(Get-PreparationUpdateKb $Update | Where-Object { $known -contains $_ }).Count -gt 0
}

# A Windows cumulative update for this build: its title names the build and a
# revision above the one installed, as in "(KB5124010) (26200.9600)".
function Test-PreparationNewerRevision($Update, $Version) {
    return (Get-PreparationTitleRevision $Update $Version.Build) -gt $Version.Ubr
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
# An installed revision at or above -MinimumRevision already has what the move
# needs, so nothing optional is taken then: an optional preview can fail where the
# monthly update installs, and it replaces that update in its pass. One that
# failed in this run isn't taken again, so the monthly update goes in instead.
function Find-PreparationPrerequisiteUpdate($Session) {
    if (-not $WindowsTarget) { return }
    $version = Get-PreparationWindowsVersion
    if (@(Get-PreparationSourceBuild) -notcontains $version.Build) { return }
    if ($MinimumRevision -gt 0 -and $version.Ubr -ge $MinimumRevision) {
        Write-AtlasTransitionEvidence "optional updates left: $($version.Build).$($version.Ubr) already has revision $MinimumRevision, which the update to $WindowsTarget needs"
        return
    }
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
        if ($script:PreparationOptionalFailed.ContainsKey((Get-PreparationUpdateKey $update))) {
            Write-AtlasTransitionEvidence "optional update left, as it failed earlier in this run: $(Format-PreparationOffer $update)"
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
    return (Wait-PreparationStoreTask $asTask.MakeGenericMethod($ResultType).Invoke($null, @($Operation)))
}

# A failed Store call ends with the Store's own error. The task wraps it twice, as
# "Exception calling Wait" around "One or more errors occurred.", which says nothing.
function Wait-PreparationStoreTask([Threading.Tasks.Task]$Task) {
    $deadline = (Get-PreparationStoreTime).AddMinutes(3)
    try {
        while (-not $Task.Wait(2000)) {
            Write-PreparationState running store-search
            if ((Get-PreparationStoreTime) -gt $deadline) {
                # A busy Store can take this long; a later call usually answers.
                # One that never does can have a stuck install service, which
                # the repairs restart first (see Repair-PreparationStore).
                $silent = New-PreparationFailure 'Microsoft Store did not answer.' 'store-timeout'
                $silent.Data['storeTransient'] = 'retry'
                $silent.Data['storeSilent'] = $true
                throw $silent
            }
        }
        return $Task.Result
    }
    catch {
        $cause = $_.Exception
        while ($null -ne $cause.InnerException -and ($cause -is [AggregateException] -or
                $cause -is [Management.Automation.MethodInvocationException] -or
                $cause -is [Management.Automation.GetValueInvocationException])) {
            $cause = $cause.InnerException
        }
        throw $cause
    }
}

function Wait-PreparationStoreSearch($Operation) {
    $resultType = [System.Collections.Generic.IReadOnlyList[Windows.ApplicationModel.Store.Preview.InstallControl.AppInstallItem]]
    return (Wait-PreparationStoreCall $Operation $resultType)
}

function New-PreparationStoreManager {
    if (-not (Get-AppxPackage -Name Microsoft.WindowsStore)) { throw (New-PreparationFailure 'Microsoft Store is not registered for this user. Open Store once, then try again.' 'store-missing') }
    return (Get-PreparationAppInstallManager)
}

# A failed update of an installed app can leave a stale record while the Store
# finishes its work. Let it settle before the next pass clears a failed record.
function Wait-PreparationStoreQueueRefresh($Manager, [string]$ProductId) {
    if (-not $ProductId) { return }
    for ($wait = 0; $wait -lt 30; $wait++) {
        Assert-PreparationContinue
        $failed = @($Manager.AppInstallItems | Where-Object {
                $_.ProductId -eq $ProductId -and [string]$_.GetCurrentStatus().InstallState -in @('Error', 'Canceled')
            })
        if ($failed.Count -eq 0) { return }
        Write-PreparationState running store-search
        Start-Sleep -Seconds 2
    }
}

# The time a Store wait reads, on its own so tests can move it on.
function Get-PreparationStoreTime { [DateTime]::UtcNow }

# How long a Store wait has run, and when what it follows last moved. $Minutes,
# when given, ends the wait that long after it began, moving or not.
function New-PreparationStoreClock([int]$Minutes = 0) {
    $now = Get-PreparationStoreTime
    $stall = if ($Minutes -gt 0) { $Minutes } else { $script:PreparationStoreStallMinutes }
    $limit = if ($Minutes -gt 0) { $Minutes } else { $script:PreparationStoreLimitMinutes }
    return [pscustomobject]@{ Started = $now; Moved = $now; Signature = $null; Stall = $stall; Limit = $limit }
}

# Ends a Store wait that has gone on too long, with store-timeout. Nothing moving
# for the clock's stall time means the Store is stuck, which a repair can help.
# A Store still moving at the clock's limit is slow, which no repair helps, so
# that timeout is marked to skip them. $Signature is what the wait follows, such
# as each item's state and percentage.
function Assert-PreparationStoreProgress($Clock, [string]$Signature, [string]$Message) {
    $now = Get-PreparationStoreTime
    if ($Signature -cne $Clock.Signature) {
        $Clock.Signature = $Signature
        $Clock.Moved = $now
    }
    if ($now -gt $Clock.Moved.AddMinutes($Clock.Stall)) {
        throw (New-PreparationFailure $Message 'store-timeout')
    }
    if ($now -gt $Clock.Started.AddMinutes($Clock.Limit)) {
        Write-PreparationStoreEvidence "still moving after $($Clock.Limit) minutes; stopping the wait without a repair"
        $slow = New-PreparationFailure $Message 'store-timeout'
        $slow.Data['storeTransient'] = 'final'
        throw $slow
    }
}

# Asks the Store to resume a queued or paused download. The Store can refuse with
# a passing COM error, such as E_FAIL, which a later try gets past.
function Resume-PreparationStoreItem($Manager, $Item) {
    try { $Manager.Restart($Item.ProductId) }
    catch {
        $refused = New-PreparationFailure "Microsoft Store couldn't resume $($Item.PackageFamilyName): $($_.Exception.Message)" 'store-timeout' (Get-PreparationHResult $_.Exception)
        $refused.Data['storeTransient'] = 'retry'
        throw $refused
    }
}

# Whether a Store failure passes on its own: 'retry' for one a later try usually
# gets past, 'final' for a slow Store that has had all the time it gets, or ''
# for any other. Test-PreparationStoreRepairable says which the repairs follow.
function Get-PreparationStoreTransient([Exception]$Exception) {
    if ($Exception.Data.Contains('storeTransient')) { return [string]$Exception.Data['storeTransient'] }
    return ''
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
        $before = Get-PreparationPackageVersion
        $operation = $manager.SearchForAllUpdatesAsync('', 'Atlas', $options)
        $items = @(Wait-PreparationStoreSearch $operation)
        # Include already active Store work so an empty new search cannot be
        # mistaken for completion while another download is still in progress.
        $items = @(@($items) + @($manager.AppInstallItems) | Group-Object PackageFamilyName | ForEach-Object { $_.Group[0] })
        Write-PreparationStoreRetried $cleared $items
        if ($items.Count -eq 0) { return }
        $clock = New-PreparationStoreClock
        $restarted = @{}
        $refresh = $null
        try {
            do {
                $complete = 0
                $percent = 0.0
                $moves = [Collections.Generic.List[string]]::new()
                foreach ($item in $items) {
                    $status = $item.GetCurrentStatus()
                    $state = [string]$status.InstallState
                    if ($state -eq 'Completed') { $complete++; $percent += 100; continue }
                    $percent += [Math]::Max(0, [Math]::Min(100, [double]$status.PercentComplete))
                    $moves.Add(('{0} {1:F0}' -f $state, [double]$status.PercentComplete))
                    # Store may return a queued download even when automatic
                    # installation was requested. WinGet restarts this state too.
                    if ($state -in @('ReadyToDownload','Paused') -and -not $restarted.ContainsKey($item.ProductId)) {
                        Resume-PreparationStoreItem $manager $item
                        $restarted[$item.ProductId] = $true
                        continue
                    }
                    if ($state -in @('Error','Canceled','Paused','PausedLowBattery','PausedWiFiRecommended','PausedWiFiRequired')) {
                        $family = [string]$item.PackageFamilyName
                        $failure = New-PreparationStoreFailure $family $state $status.ErrorCode
                        if (-not $script:PreparationStoreQueueRefreshed -and $pass -lt ($script:PreparationPasses - 1) -and
                            $state -in @('Error', 'Canceled') -and $before.ContainsKey($family) -and
                            -not $cleared.ContainsKey($family) -and $failure.Data['errorCode'] -notin @('0x80073D02', '0x80240016')) {
                            $refresh = $item
                            break
                        }
                        throw $failure
                    }
                }
                if ($null -ne $refresh) { break }
                Write-PreparationState running store-install $complete $items.Count -Detail @{percent = [int][Math]::Floor($percent / $items.Count)}
                if ($complete -lt $items.Count) {
                    Assert-PreparationStoreProgress $clock "$complete $($moves -join ',')" 'Store apps have not finished updating. Open Microsoft Store and resolve the remaining downloads.'
                    Start-Sleep -Seconds 2
                }
            } while ($complete -lt $items.Count)
        }
        finally { Write-PreparationStoreItem $items $before }
        Assert-PreparationContinue
        if ($null -ne $refresh) {
            $script:PreparationStoreQueueRefreshed = $true
            Write-PreparationStoreEvidence "item $($refresh.PackageFamilyName): waiting for the failed queue entry to settle, then searching again"
            Wait-PreparationStoreQueueRefresh $manager ([string]$refresh.ProductId)
            continue
        }
        # Updating Store itself can reveal more updates; search again before finishing.
        $again = @(Wait-PreparationStoreSearch ($manager.SearchForAllUpdatesAsync('', 'Atlas', $options)))
        if (@(@($again) + @($manager.AppInstallItems) | Where-Object { [string]$_.GetCurrentStatus().InstallState -ne 'Completed' }).Count -eq 0) { return }
    }
    throw (New-PreparationFailure "Microsoft Store still offers updates after $script:PreparationPasses passes." 'store-passes')
}

function Assert-PreparationWindowsCurrent($Session, [string]$Phase, [string]$Message) {
    $required = @(Find-PreparationWindowsUpdate $Session)
    if ($required.Count -eq 0) { return }

    Write-PreparationLog "Verification found $($required.Count) required Windows update(s) $Phase the Store check (driver mode: $DriverMode)."
    foreach ($update in ($required | Select-Object -First 20)) {
        $title = ([string]$update.Title -replace '\s+', ' ').Trim()
        $kb = @(Get-PreparationUpdateKb $update)
        $reference = if ($kb.Count -gt 0) { " (KB: $($kb -join ', '))" } else { '' }
        Write-PreparationLog "Required update: $title$reference"
    }
    throw $Message
}

function Assert-PreparationCurrent {
    Assert-PreparationContinue
    Assert-PreparationUser
    if (Test-PreparationRestart) { throw "Restart Windows and run preparation again before installing Atlas (pending: $($script:PreparationRestartReasons -join ', '))." }
    if (-not (Test-PreparationNetwork)) { throw 'Connect to unrestricted internet before verifying Windows and Store updates.' }
    Write-PreparationState running windows-search
    $session = New-Object -ComObject Microsoft.Update.Session
    $session.ClientApplicationID = 'Atlas preparation verification'
    Assert-PreparationWindowsCurrent $session 'before' `
        'Windows still offers required updates. Finish preparation in Atlas, then retry installation.'
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
    Assert-PreparationWindowsCurrent $session 'after' `
        'Windows offered additional updates during verification. Finish preparation, then retry.'
    if (Test-PreparationRestart) { throw "Restart Windows before installing Atlas (pending: $($script:PreparationRestartReasons -join ', '))." }
    if (-not (Test-PreparationNetwork)) { throw 'The internet connection changed during preparation verification.' }
}

# Runs $Action, the Store apps' pass unless given another Store call, and returns
# what it returns.
function Invoke-PreparationStoreWithRetry([scriptblock]$Action = { Invoke-PreparationStore }) {
    # Retry what passes on its own: another install in progress (0x80240016), an app
    # whose files are in use (0x80073D02), which the Store's forced restart of the
    # app or the user closing it gets past, and a Store that cancelled an item
    # (E_ABORT), didn't answer or couldn't resume a download. Never an unknown error.
    # An app still in use after the last try is left to the user to close; any other
    # failure the last try doesn't get past goes on to the repairs, as any Store
    # failure does.
    for ($attempt = 0; $attempt -lt 4; $attempt++) {
        try { return (& $Action) }
        catch {
            $detail = Get-PreparationFailureDetail $_.Exception
            $code = if ($detail.ContainsKey('errorCode')) { $detail.errorCode } else { '' }
            $busy = $code -eq '0x80240016'
            $inUse = $code -eq '0x80073D02'
            $passing = (Get-PreparationStoreTransient $_.Exception) -eq 'retry'
            if (-not ($busy -or $inUse -or $passing) -or $attempt -eq 3 -or (Test-PreparationRestart)) { throw }
            if ($busy) { Write-PreparationLog "Store is busy; retrying in 15 seconds (attempt $($attempt + 2) of 4)." }
            elseif ($inUse) {
                $app = if ($detail.ContainsKey('packageName')) { $detail.packageName } else { 'an app' }
                Write-PreparationStoreEvidence "$app is in use (0x80073D02); trying again in 15 seconds (attempt $($attempt + 2) of 4)"
            }
            else { Write-PreparationStoreEvidence "$(([string]$_.Exception.Message).Trim().TrimEnd('.')); trying again in 15 seconds (attempt $($attempt + 2) of 4)" }
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
# from Microsoft) and the Store through winget, then StoreFixer. A Store that
# didn't answer gets a restart of its install service first ('installservice').
$script:PreparationStoreRepairs = @('wsreset', 'bootstrap', 'storefixer')
# Whether the bootstrap downloaded App Installer, rather than registering the
# copy this PC already had.
$script:PreparationStoreDownloaded = $false
$script:PreparationStoreRepairsRun = $false
$script:PreparationStoreQueueRefreshed = $false
# E_ABORT (0x80004004), which the Store gives an item something interrupted.
$script:StoreAborted = -2147467260
# A Store wait gives up once nothing has moved for this long, and in any case
# after the limit; a Store that still moves at the limit is slow, not broken.
$script:PreparationStoreStallMinutes = 30
$script:PreparationStoreLimitMinutes = 90
# What happened to the Store in this run, for the app: store-updated,
# store-bootstrapped, store-repaired or store-skipped-removed.
$script:PreparationStoreOutcome = $null
# winget-cli's GitHub repository and its owner, by the ids GitHub gives them,
# so a renamed or replaced repository is refused.
$script:PreparationWingetRepository = 'microsoft/winget-cli'
$script:PreparationWingetRepositoryId = 197275130
$script:PreparationWingetOwnerId = 6154722
$script:PreparationMicrosoftPublisher = 'CN=Microsoft Corporation, O=Microsoft Corporation, L=Redmond, S=Washington, C=US'
# Win32 errors 15600 to 15699 (0x80073CF0 to 0x80073D53): Windows refused to
# deploy a package. The Store reports most as 0x80073CF9, the install failed;
# the AppX deployment log's events 401 and 404 say why, as in 0x80070490.
$script:DeploymentErrorFirst = -2147009296
$script:DeploymentErrorLast = -2147009197
$script:PreparationDeploymentLog = 'Microsoft-Windows-AppXDeploymentServer/Operational'
# How much of that log updates.log takes: a failing Store retries and logs the
# same failure each time, so each text is written once a run, cut at a length,
# at most a few for each package each time an item fails, and only so many a run.
$script:PreparationDeploymentPerPackage = 4
$script:PreparationDeploymentLimit = 24
$script:PreparationDeploymentLength = 1500
$script:PreparationDeploymentSeen = [Collections.Generic.HashSet[string]]::new()
$script:PreparationDeploymentWritten = 0
$script:PreparationStateRepositoryRead = $false
# A package full name: name, version, architecture, resource id, publisher id.
$script:PackageFullNamePattern = '\b[A-Za-z0-9][A-Za-z0-9.-]*_\d+(\.\d+){3}_[A-Za-z0-9]+_[^\s_]*_[a-z0-9]{13}\b'
# ERROR_NOT_FOUND (0x80070490), element not found: Windows couldn't stage a package. Event
# 401 of the AppX deployment log gives it for the Stage of a Store update, or the Add of a
# downloaded package, and its DeploymentOperation value says which: 1 is Add, 4 is Stage.
$script:StagingNotFound = -2147023728
$script:StagingOperations = @(1, 4)
# A Store the repairs didn't help, whose run has Windows unable to stage updates for two
# or more apps, or for App Installer's own bundle, stops with store-appx-staging. The
# repairs run in at most this many runs that end that way; a record beside the one of
# updates offered again counts them (see Read-PreparationStagingRecord).
$script:PreparationStagingRepairs = 2
# The activity id Add-AppxPackage named when the bootstrap's App Installer bundle failed
# with 0x80070490, '' when it named none, and $null when the bundle didn't fail so.
$script:PreparationStagingBootstrap = $null
$script:PreparationStagingEvidenceWritten = $false
# How much read-only evidence of a staging failure updates.log takes: so many apps, so
# many events of each failing deployment and of the run's AppX deployment log, so many
# entries of each kind for each app, each line cut at a length, and only so long reading.
$script:PreparationStagingApps = 8
$script:PreparationStagingActivityEvents = 25
$script:PreparationStagingRunEvents = 30
$script:PreparationStagingEntries = 6
$script:PreparationStagingLength = 600
$script:PreparationStagingSeconds = 90
$script:PreparationAllUserStore = 'SOFTWARE\Microsoft\Windows\CurrentVersion\Appx\AppxAllUserStore'

function Write-PreparationStoreEvidence([string]$Text) {
    Write-PreparationLog "Microsoft Store: $Text"
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
# this user had before and has now, and how it ended, with the Store's code for
# an error. Items Windows refused to deploy are followed by what the AppX
# deployment log says.
function Write-PreparationStoreItem($Items, [hashtable]$Before) {
    $refused = @()
    try {
        $after = Get-PreparationPackageVersion
        foreach ($item in @($Items)) {
            $family = [string]$item.PackageFamilyName
            $state = try { $status = $item.GetCurrentStatus(); [string]$status.InstallState } catch { 'unreadable' }
            $code = 0
            if ($state -eq 'Error') {
                $errorCode = $status.PSObject.Properties['ErrorCode']
                if ($null -ne $errorCode -and $null -ne $errorCode.Value) { $code = [int]$errorCode.Value.HResult }
            }
            $from = if ($Before.ContainsKey($family)) { $Before[$family] } else { 'none' }
            $to = if ($after.ContainsKey($family)) { $after[$family] } else { 'none' }
            $product = if ([string]$item.ProductId) { " ($($item.ProductId))" } else { '' }
            $ended = if ($code -ne 0) { '{0}, 0x{1:X8}' -f $state, $code } else { $state }
            Write-PreparationStoreEvidence "item $family$product`: $from -> $to, $ended"
            if ($code -ge $script:DeploymentErrorFirst -and $code -le $script:DeploymentErrorLast) { $refused += '{0} (0x{1:X8})' -f $family, $code }
        }
    }
    catch { Write-PreparationStoreEvidence "the Store items could not be listed: $($_.Exception.Message)" }
    if ($refused.Count -gt 0) { Write-PreparationDeploymentEvent $refused }
}

# A missing element during staging can have more detail in StateRepository.
# Keep only nearby errors relevant to the package or the same error code.
function Write-PreparationStateRepositoryEvent([string]$Package, [datetime]$At) {
    $script:PreparationStateRepositoryRead = $true
    $start = $At.AddSeconds(-30)
    if ($start -lt $script:PreparationStartedAt) { $start = $script:PreparationStartedAt }
    $filter = @{
        LogName = 'Microsoft-Windows-StateRepository/Operational'
        Level = 2
        StartTime = $start
        EndTime = $At.AddSeconds(30)
    }
    try {
        $packageName = [regex]::Escape(($Package -split '_')[0])
        $events = @(Get-WinEvent -FilterHashtable $filter -MaxEvents 100 -ErrorAction Stop |
                Where-Object Message -Match "$packageName|0x80070490|-2147023728" | Select-Object -First 5)
        foreach ($entry in $events) {
            $text = ([string]$entry.Message -replace '\s+', ' ').Trim()
            if ($text.Length -gt $script:PreparationDeploymentLength) { $text = $text.Substring(0, $script:PreparationDeploymentLength) + '...' }
            Write-PreparationLog ('Microsoft Store: StateRepository event {0} at {1:yyyy-MM-dd HH:mm:ss}: {2}' -f $entry.Id, $entry.TimeCreated, $text)
        }
    }
    catch {
        if ([string]$_.FullyQualifiedErrorId -notlike 'NoMatchingEventsFound*') {
            Write-PreparationLog "Microsoft Store: StateRepository log couldn't be read: $($_.Exception.Message)"
        }
    }
}

# An event's text on one line. Windows PowerShell can't always render a
# provider's text; the event's own values still carry the package and the error.
function Get-PreparationEventText($Entry) {
    $text = ([string]$Entry.Message -replace '\s+', ' ').Trim()
    if ($text) { return $text }
    $values = $Entry.PSObject.Properties['Properties']
    return 'no text; values: ' + $(if ($null -ne $values) { @($values.Value | ForEach-Object { [string]$_.Value }) -join '; ' } else { 'none' })
}

# The AppX deployment log's events 401 (a deployment step failed, with that
# step's own error) and 404 (the deployment failed) since this run started,
# under the package each names, in updates.log; windows-transition.log only
# notes them. A log read failure is recorded and does not stop the run.
function Write-PreparationDeploymentEvent([string[]]$Refused) {
    $intro = "$($Refused -join ', ') failed to deploy; the AppX deployment log since this run started"
    try {
        try {
            $filter = @{ LogName = $script:PreparationDeploymentLog; Id = @(401, 404); StartTime = $script:PreparationStartedAt }
            $events = @(Get-WinEvent -FilterHashtable $filter -MaxEvents 500 -ErrorAction Stop)
        }
        catch {
            # Get-WinEvent reports a query that matches nothing as an error.
            if ([string]$_.FullyQualifiedErrorId -notlike 'NoMatchingEventsFound*') { throw }
            $events = @()
        }
        # Newest first, as Get-WinEvent returns them, so each package keeps its
        # newest; they are written oldest first, as they happened.
        $packages = [ordered]@{}
        # Each text counts once here, but only what is written joins the run's
        # seen texts, so a later failure can still write what a limit left out.
        $counted = [Collections.Generic.HashSet[string]]::new()
        $kept = 0
        $left = 0
        $missing = $null
        foreach ($entry in $events) {
            $text = Get-PreparationEventText $entry
            $key = "$($entry.Id) $text"
            if ($script:PreparationDeploymentSeen.Contains($key) -or -not $counted.Add($key)) { continue }
            $named = [regex]::Match($text, $script:PackageFullNamePattern)
            $package = if ($named.Success) { $named.Value } else { 'no package named' }
            if ($null -eq $missing -and $named.Success -and $null -ne $entry.TimeCreated -and $text -match '0x80070490|-2147023728') {
                $missing = @{ Package = $package; At = $entry.TimeCreated }
            }
            if (-not $packages.Contains($package)) { $packages[$package] = [Collections.Generic.List[string]]::new() }
            if ($packages[$package].Count -ge $script:PreparationDeploymentPerPackage -or
                $script:PreparationDeploymentWritten + $kept -ge $script:PreparationDeploymentLimit) {
                $left++
                continue
            }
            [void]$script:PreparationDeploymentSeen.Add($key)
            if ($text.Length -gt $script:PreparationDeploymentLength) { $text = $text.Substring(0, $script:PreparationDeploymentLength) + '...' }
            $packages[$package].Insert(0, ('event {0} at {1:yyyy-MM-dd HH:mm:ss}: {2}' -f $entry.Id, $entry.TimeCreated, $text))
            $kept++
        }
        if ($null -ne $missing -and -not $script:PreparationStateRepositoryRead) {
            Write-PreparationStateRepositoryEvent @missing
        }
        if ($kept -eq 0) {
            # Each package's first new event is kept unless the run's limit is reached.
            if ($left) { Write-PreparationStoreEvidence "$intro has $left more event(s) 401 or 404, left out: updates.log already has the $script:PreparationDeploymentLimit deployment events a run takes" }
            else { Write-PreparationStoreEvidence "$intro has no event 401 or 404 that updates.log doesn't have already" }
            return
        }
        Write-PreparationLog "Microsoft Store: $intro says:"
        foreach ($package in $packages.Keys) {
            foreach ($line in $packages[$package]) { Write-PreparationLog "Microsoft Store: deployment of $package, $line" }
        }
        $script:PreparationDeploymentWritten += $kept
        Write-AtlasTransitionEvidence "store: $intro has $kept new event(s) 401 or 404; updates.log has them"
        if ($left) {
            Write-PreparationStoreEvidence "$left more deployment event(s) left out: updates.log takes the newest $script:PreparationDeploymentPerPackage for each package each time an item fails, and $script:PreparationDeploymentLimit a run"
        }
    }
    catch { Write-PreparationStoreEvidence "$intro couldn't be read: $($_.Exception.Message)" }
}

# The package an event 401 names when it's a Stage or an Add that failed with
# 0x80070490, or ''. The event's own values say so in any language; its text,
# where they're missing, keeps the operation's English name in every language.
function Get-PreparationStagingPackage($Entry) {
    $values = $Entry.PSObject.Properties['Properties']
    $data = @(if ($null -ne $values -and $null -ne $values.Value) { $values.Value | ForEach-Object { $_.Value } })
    if ($data.Count -ge 4 -and $null -ne ($data[0] -as [long]) -and $null -ne ($data[3] -as [long])) {
        # ErrorCode is a HexInt32, which can come as an unsigned value.
        $code = [long]$data[3]
        if ($code -gt [int]::MaxValue) { $code -= 4294967296 }
        if ($script:StagingOperations -contains [long]$data[0] -and $code -eq $script:StagingNotFound) { return [string]$data[1] }
        return ''
    }
    $text = [string]$Entry.Message
    if ($text -notmatch '0x80070490' -or $text -notmatch '(?<![\w.-])(Stage|Add)(?![\w.-])') { return '' }
    $named = [regex]::Match($text, $script:PackageFullNamePattern)
    if ($named.Success) { return $named.Value }
    return ''
}

# Each app Windows couldn't stage an update for in this run (see
# Get-PreparationStagingPackage), newest first, once by package name: its family,
# the package full name and the deployment's activity id. A log that can't be
# read gives none, and updates.log says so.
function Get-PreparationStagingFailure {
    try {
        $filter = @{ LogName = $script:PreparationDeploymentLog; Id = 401; StartTime = $script:PreparationStartedAt }
        $events = @(Get-WinEvent -FilterHashtable $filter -MaxEvents 500 -ErrorAction Stop)
    }
    catch {
        if ([string]$_.FullyQualifiedErrorId -notlike 'NoMatchingEventsFound*') {
            Write-PreparationLog "Microsoft Store: the AppX deployment log couldn't be read for staging failures: $($_.Exception.Message)"
        }
        return
    }
    $named = @{}
    foreach ($entry in $events) {
        $package = Get-PreparationStagingPackage $entry
        if (-not $package) { continue }
        $name = ($package -split '_')[0]
        if ($named.ContainsKey($name)) { continue }
        $named[$name] = $true
        $activity = $entry.PSObject.Properties['ActivityId']
        [pscustomobject]@{
            Name = $name
            Family = '{0}_{1}' -f $name, $package.Substring($package.LastIndexOf('_') + 1)
            Package = $package
            ActivityId = if ($null -ne $activity -and $null -ne $activity.Value) { [string]$activity.Value } else { '' }
        }
    }
}

# Notes the bootstrap's App Installer bundle failing with 0x80070490, by the
# activity id Add-AppxPackage's error names.
function Register-PreparationBootstrapStaging([Exception]$Exception) {
    $text = [string]$Exception.Message
    if ($text -notmatch '0x80070490') { return }
    $activity = [regex]::Match($text, '\[ActivityId\]\s*([0-9A-Fa-f]{8}(-[0-9A-Fa-f]{4}){3}-[0-9A-Fa-f]{12})')
    $script:PreparationStagingBootstrap = if ($activity.Success) { $activity.Groups[1].Value } else { '' }
}

# The apps of a staging failure, by package name, after the repairs didn't help:
# App Installer's own bundle that the bootstrap couldn't add, or updates for two or
# more apps that Windows couldn't stage while the Store still fails to deploy one.
# None for any other failure, which stays store-repair-failed.
function Get-PreparationStagingApp($Staging, [Exception]$Last) {
    $names = [Collections.Generic.List[string]]::new()
    foreach ($entry in @($Staging | Where-Object { $null -ne $_ })) { $names.Add([string]$entry.Name) }
    $bootstrap = $null -ne $script:PreparationStagingBootstrap
    if ($bootstrap -and -not $names.Contains('Microsoft.DesktopAppInstaller')) { $names.Add('Microsoft.DesktopAppInstaller') }
    $code = (Get-PreparationFailureDetail $Last)['errorCode']
    $hresult = if ($code) { [Convert]::ToInt32($code, 16) } else { 0 }
    $deploying = $hresult -eq $script:StagingNotFound -or ($hresult -ge $script:DeploymentErrorFirst -and $hresult -le $script:DeploymentErrorLast)
    if ($bootstrap -or ($deploying -and $names.Count -ge 2)) { return $names.ToArray() }
}

# The record of a staging failure the repairs didn't help, beside the record of
# updates offered again: the apps, when, and in how many runs the repairs met it.
function Get-PreparationStagingRecordText {
    $value = Get-AtlasTransitionValue $script:PreparationReofferedRoot 'StoreStaging'
    if ($value.Present -and $value.Kind -eq 'String') { return [string]$value.Data }
    return ''
}

function Set-PreparationStagingRecordText([string]$Text) {
    if ($Text) { Set-AtlasTransitionValue $script:PreparationReofferedRoot 'StoreStaging' 'String' $Text }
    else { Remove-AtlasTransitionValue $script:PreparationReofferedRoot 'StoreStaging' }
}

# The record, or $null when there's none. One more than 30 days old belongs to an
# earlier preparation, and counts for nothing.
function Read-PreparationStagingRecord {
    try {
        $text = Get-PreparationStagingRecordText
        if (-not $text) { return $null }
        $record = $text | ConvertFrom-Json -ErrorAction Stop
        $field = { param([string]$Name) $property = $record.PSObject.Properties[$Name]; if ($null -ne $property) { $property.Value } }
        $at = [DateTime]::MinValue
        if (-not [DateTime]::TryParse([string](& $field 'at'), [Globalization.CultureInfo]::InvariantCulture,
                [Globalization.DateTimeStyles]::AdjustToUniversal, [ref]$at) -or $at -lt [DateTime]::UtcNow.AddDays(-30)) { return $null }
        $apps = @(@(& $field 'apps') | ForEach-Object { [string]$_ } | Where-Object { $_ -match '^[A-Za-z0-9][A-Za-z0-9.-]{0,99}$' })
        return [pscustomobject]@{ At = $at; Apps = $apps; Repairs = [int](& $field 'repairs') }
    }
    catch {
        Write-PreparationLog "Microsoft Store: the record of its AppX staging failures couldn't be read: $($_.Exception.Message)"
        return $null
    }
}

# Records a staging failure the repairs met in $Repairs runs. A record that can't be
# written is logged: the next run then repairs again.
function Save-PreparationStagingRecord([string[]]$Apps, [int]$Repairs) {
    try {
        $record = [pscustomobject][ordered]@{ at = [DateTime]::UtcNow.ToString('o'); apps = @($Apps | Select-Object -First 20); repairs = $Repairs }
        Set-PreparationStagingRecordText (ConvertTo-Json -InputObject $record -Compress)
    }
    catch { Write-PreparationLog "Microsoft Store: its AppX staging failure couldn't be recorded: $($_.Exception.Message)" }
}

# Clears the record once the Store works. Without one there's nothing to clear.
function Clear-PreparationStagingRecord {
    try {
        if (-not (Get-PreparationStagingRecordText)) { return }
        Set-PreparationStagingRecordText ''
        Write-PreparationStoreEvidence 'works, so the record of its AppX staging failures is cleared'
    }
    catch { Write-PreparationLog "Microsoft Store: the record of its AppX staging failures couldn't be cleared: $($_.Exception.Message)" }
}

# One line of staging evidence in updates.log, cut at a length.
function Write-PreparationStagingLine([string]$Text) {
    $line = ($Text -replace '\s+', ' ').Trim()
    if ($line.Length -gt $script:PreparationStagingLength) { $line = $line.Substring(0, $script:PreparationStagingLength) + '...' }
    Write-PreparationLog "Microsoft Store: staging evidence: $line"
}

# Whether reading the evidence has taken its time, which the log then says.
function Test-PreparationStagingLate($Clock) {
    if ($Clock.Elapsed.TotalSeconds -lt $script:PreparationStagingSeconds) { return $false }
    Write-PreparationStagingLine "stopped after $script:PreparationStagingSeconds seconds; the rest is left out"
    return $true
}

# The events of one AppX deployment, oldest first: what Get-AppPackageLog
# -ActivityID gives, through a query each log filters itself, as that command reads
# every event of every AppX log first.
function Get-PreparationAppxActivityEvent([string]$ActivityId) {
    $query = "*[System[Correlation[@ActivityID='{0}']]]" -f ([guid]$ActivityId).ToString('B')
    $logs = @(Get-WinEvent -ListLog 'Microsoft-Windows-Appx*' -ErrorAction SilentlyContinue |
            Where-Object { $_.IsEnabled -and [string]$_.LogType -in @('Administrative', 'Operational') } | ForEach-Object { $_.LogName })
    $events = foreach ($log in $logs) {
        try { Get-WinEvent -LogName $log -FilterXPath $query -MaxEvents $script:PreparationStagingActivityEvents -ErrorAction Stop }
        catch { if ([string]$_.FullyQualifiedErrorId -notlike 'NoMatchingEventsFound*') { throw } }
    }
    @($events | Sort-Object TimeCreated | Select-Object -First $script:PreparationStagingActivityEvents)
}

# The subkeys of one place in the AppX store's registry, with the manifest each
# names; nothing when the place is missing.
function Get-PreparationAllUserStoreEntry([string]$Place) {
    $key = [Microsoft.Win32.Registry]::LocalMachine.OpenSubKey("$script:PreparationAllUserStore\$Place", $false)
    if ($null -eq $key) { return }
    try {
        foreach ($name in @($key.GetSubKeyNames())) {
            $path = ''
            $entry = $key.OpenSubKey($name, $false)
            if ($null -ne $entry) {
                try { $path = [string]$entry.GetValue('Path') }
                finally { $entry.Dispose() }
            }
            [pscustomobject]@{ Key = $name; Path = $path }
        }
    }
    finally { $key.Dispose() }
}

# Whether Windows keeps a package's manifest in its app repository.
function Test-PreparationAppRepositoryManifest([string]$PackageFullName) {
    [IO.File]::Exists([IO.Path]::Combine([Environment]::GetFolderPath('CommonApplicationData'), 'Microsoft\Windows\AppRepository', "$PackageFullName.xml"))
}

# Read-only evidence of a staging failure, in updates.log, once a run: the events
# of each failing deployment, the AppX deployment log's errors and warnings since
# the run started, and what Windows records of each app (its packages for every
# account, its provisioned packages, its entries in the AppX store's registry and
# its manifest in the app repository). Each part takes so much and the whole so
# long (see $script:PreparationStagingApps); a part that fails is noted, and
# nothing here changes the outcome.
function Write-PreparationStagingEvidence([string[]]$Apps, $Staging) {
    if ($script:PreparationStagingEvidenceWritten) { return }
    $script:PreparationStagingEvidenceWritten = $true
    $clock = [Diagnostics.Stopwatch]::StartNew()
    $names = @($Apps | Select-Object -First $script:PreparationStagingApps)
    Write-PreparationStagingLine "Windows couldn't stage updates for $($names -join ', '); what Windows records of them follows"
    Write-AtlasTransitionEvidence "store: Windows couldn't stage updates for $($names -join ', ') (0x80070490); updates.log has the evidence"

    $activities = [ordered]@{}
    $families = @{}
    foreach ($entry in @($Staging | Where-Object { $null -ne $_ })) {
        $families[[string]$entry.Name] = [string]$entry.Family
        if ($entry.ActivityId -and -not $activities.Contains([string]$entry.ActivityId)) { $activities[[string]$entry.ActivityId] = [string]$entry.Package }
    }
    if ($script:PreparationStagingBootstrap) { $activities[$script:PreparationStagingBootstrap] = 'the App Installer bundle the bootstrap added' }
    foreach ($id in @($activities.Keys | Select-Object -First $script:PreparationStagingApps)) {
        if (Test-PreparationStagingLate $clock) { return }
        Write-PreparationState running $script:PreparationStage
        try {
            $logged = @(Get-PreparationAppxActivityEvent $id)
            Write-PreparationStagingLine "deployment $id ($($activities[$id])): $($logged.Count) event(s)"
            foreach ($record in $logged) {
                Write-PreparationStagingLine ('deployment {0}: {1} event {2} at {3:yyyy-MM-dd HH:mm:ss}: {4}' -f $id, $record.LogName, $record.Id, $record.TimeCreated, (Get-PreparationEventText $record))
            }
        }
        catch { Write-PreparationStagingLine "deployment $id couldn't be read: $($_.Exception.Message)" }
    }

    if (Test-PreparationStagingLate $clock) { return }
    try {
        try {
            $filter = @{ LogName = $script:PreparationDeploymentLog; Level = @(1, 2, 3); StartTime = $script:PreparationStartedAt }
            $logged = @(Get-WinEvent -FilterHashtable $filter -MaxEvents 200 -ErrorAction Stop)
        }
        catch {
            if ([string]$_.FullyQualifiedErrorId -notlike 'NoMatchingEventsFound*') { throw }
            $logged = @()
        }
        # Newest first, as Get-WinEvent returns them; written oldest first.
        $kept = [Collections.Generic.List[string]]::new()
        $counted = [Collections.Generic.HashSet[string]]::new()
        foreach ($record in $logged) {
            $text = Get-PreparationEventText $record
            $key = "$($record.Id) $text"
            if ($script:PreparationDeploymentSeen.Contains($key) -or -not $counted.Add($key)) { continue }
            if ($kept.Count -ge $script:PreparationStagingRunEvents) { break }
            $kept.Add(('event {0} at {1:yyyy-MM-dd HH:mm:ss}: {2}' -f $record.Id, $record.TimeCreated, $text))
        }
        Write-PreparationStagingLine "the AppX deployment log's errors and warnings since this run started that updates.log doesn't have already: $($kept.Count)$(if ($kept.Count -ge $script:PreparationStagingRunEvents) { ', the newest' })"
        for ($index = $kept.Count - 1; $index -ge 0; $index--) { Write-PreparationStagingLine $kept[$index] }
    }
    catch { Write-PreparationStagingLine "the AppX deployment log couldn't be read: $($_.Exception.Message)" }

    if (Test-PreparationStagingLate $clock) { return }
    Write-PreparationState running $script:PreparationStage
    try { $provisioned = @(Get-AppxProvisionedPackage -Online -ErrorAction Stop) }
    catch {
        $provisioned = $null
        Write-PreparationStagingLine "the provisioned packages couldn't be listed: $($_.Exception.Message)"
    }
    $places = [ordered]@{}
    foreach ($place in @('Applications', 'InboxApplications', 'Deprovisioned')) {
        try { $places[$place] = @(Get-PreparationAllUserStoreEntry $place) }
        catch { Write-PreparationStagingLine "AppxAllUserStore\$place couldn't be read: $($_.Exception.Message)" }
    }
    foreach ($name in $names) {
        if (Test-PreparationStagingLate $clock) { return }
        Write-PreparationState running $script:PreparationStage
        $family = if ($families.ContainsKey($name)) { $families[$name] } elseif ($name -eq 'Microsoft.DesktopAppInstaller') { $script:PreparationAppInstallerFamily } else { '' }
        $publisher = if ($family) { $family.Substring($family.LastIndexOf('_') + 1) } else { '' }
        try {
            $packages = @(Get-AppxPackage -AllUsers -Name $name -ErrorAction Stop | Where-Object { -not $family -or [string]$_.PackageFamilyName -eq $family } |
                    Sort-Object { [version]$_.Version } -Descending | Select-Object -First $script:PreparationStagingEntries)
            if ($packages.Count -eq 0) { Write-PreparationStagingLine "$name`: no package for any account" }
            foreach ($package in $packages) {
                # Accounts by SID only, as an account's name would reach reports.
                $users = try {
                    @($package.PackageUserInformation | Where-Object { $null -ne $_ } | ForEach-Object { '{0}: {1}' -f $_.UserSecurityId.Sid, $_.InstallState }) -join '; '
                }
                catch { 'accounts unreadable' }
                $manifest = if (Test-PreparationAppRepositoryManifest $package.PackageFullName) { 'present' } else { 'missing' }
                Write-PreparationStagingLine "$name`: package $($package.PackageFullName), $($package.Status)$(if ($users) { " ($users)" }); AppRepository\$($package.PackageFullName).xml $manifest"
            }
        }
        catch { Write-PreparationStagingLine "$name`: its packages couldn't be listed: $($_.Exception.Message)" }
        if ($null -ne $provisioned) {
            $mine = @($provisioned | Where-Object { [string]$_.DisplayName -eq $name } | Select-Object -First $script:PreparationStagingEntries)
            if ($mine.Count -eq 0) { Write-PreparationStagingLine "$name`: not provisioned" }
            foreach ($package in $mine) { Write-PreparationStagingLine "$name`: provisioned $($package.PackageName)" }
        }
        $found = 0
        foreach ($place in $places.Keys) {
            $entries = @($places[$place] | Where-Object {
                    $key = [string]$_.Key
                    if ($place -eq 'Deprovisioned') { if ($family) { $key -eq $family } else { $key -like "$name`_*" } }
                    else { $key -like "$name`_*" -and (-not $publisher -or $key -like "*_$publisher") }
                } | Select-Object -First $script:PreparationStagingEntries)
            foreach ($entry in $entries) {
                $found++
                $path = if (-not $entry.Path) { '' }
                elseif ([IO.File]::Exists($entry.Path) -or [IO.Directory]::Exists($entry.Path)) { ", $($entry.Path) present" }
                else { ", $($entry.Path) missing" }
                Write-PreparationStagingLine "$name`: AppxAllUserStore\$place\$($entry.Key)$path"
            }
        }
        if ($found -eq 0) { Write-PreparationStagingLine "$name`: no entry in AppxAllUserStore\$(@($places.Keys) -join ', ')" }
    }
}

# Ends the Store stage for a staging failure: the evidence, then store-appx-staging,
# which names the apps and leaves reinstalling Windows as the way on. $Repairs says
# how the repairs went.
function Stop-PreparationStoreStaging([string[]]$Apps, $Staging, [string]$Repairs) {
    Write-PreparationStagingEvidence $Apps $Staging
    $failure = New-PreparationFailure "Windows couldn't stage updates for these built-in apps (0x80070490, element not found): $($Apps -join ', '). $Repairs" 'store-appx-staging' $script:StagingNotFound
    $failure.Data['packageName'] = @($Apps | ForEach-Object { $_.Split('.')[-1] }) -join ','
    throw $failure
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
# once, as WinGet does; any other stop fails. The wait ends as
# Assert-PreparationStoreProgress says, or after $Minutes when given.
function Wait-PreparationStoreItem($Manager, $Item, [string]$Stage, [int]$Minutes = 0) {
    $clock = New-PreparationStoreClock $Minutes
    $restarted = $false
    while ($true) {
        Assert-PreparationContinue
        $status = $Item.GetCurrentStatus()
        $state = [string]$status.InstallState
        if ($state -eq 'Completed') { return }
        if ($state -in @('ReadyToDownload', 'Paused') -and -not $restarted) {
            Resume-PreparationStoreItem $Manager $Item
            $restarted = $true
        }
        elseif ($state -in @('Error', 'Canceled', 'Paused', 'PausedLowBattery', 'PausedWiFiRecommended', 'PausedWiFiRequired')) {
            throw (New-PreparationStoreFailure $Item.PackageFamilyName $state $status.ErrorCode)
        }
        $percent = [int][Math]::Max(0, [Math]::Min(100, [double]$status.PercentComplete))
        Write-PreparationState running $Stage -Detail @{ percent = $percent }
        Assert-PreparationStoreProgress $clock "$state $percent" "Microsoft Store has not finished updating $($Item.PackageFamilyName)."
        Start-Sleep -Seconds 2
    }
}

# Asks the Store to update itself, then App Installer, by package family, and
# waits for each. App Installer only helps; a Store that can't update fails.
# With -Retry, the Store's own update gets the tries the Store apps get
# (Invoke-PreparationStoreWithRetry), as the first try before the repairs; after
# a repair, one try says whether it helped. Returns whether either was updated.
function Update-PreparationStoreItself([switch]$Retry) {
    $manager = New-PreparationStoreManager
    $updated = $false
    foreach ($family in @($script:PreparationStoreFamily, $script:PreparationAppInstallerFamily)) {
        Assert-PreparationContinue
        try {
            $result = if ($Retry -and $family -eq $script:PreparationStoreFamily) {
                Invoke-PreparationStoreWithRetry { Update-PreparationStoreFamily $manager $family }
            }
            else { Update-PreparationStoreFamily $manager $family }
            if (@($result) -contains $true) { $updated = $true }
        }
        catch {
            # App Installer only helps: whatever a repair could help with, or a
            # Store slow to the end, leaves it as it is.
            $slow = (Get-PreparationStoreTransient $_.Exception) -eq 'final'
            if ($family -eq $script:PreparationStoreFamily -or -not ((Test-PreparationStoreRepairable $_.Exception) -or $slow)) { throw }
            Write-PreparationStoreEvidence "$family could not be updated, going on: $($_.Exception.Message)"
        }
    }
    return $updated
}

# Asks the Store to update one package family and follows the update to its end.
# Returns whether there was one.
function Update-PreparationStoreFamily($Manager, [string]$Family) {
    $itemType = [Windows.ApplicationModel.Store.Preview.InstallControl.AppInstallItem]
    $item = Wait-PreparationStoreCall ($Manager.UpdateAppByPackageFamilyNameAsync($Family)) $itemType
    if ($null -eq $item) {
        Write-PreparationStoreEvidence "$Family has no update"
        return $false
    }
    Write-PreparationStoreEvidence "$Family is out of date; updating it"
    $before = Get-PreparationPackageVersion
    try { Wait-PreparationStoreItem $Manager $item store-self-update }
    finally { Write-PreparationStoreItem @($item) $before }
    return $true
}

# Failures a Store repair can help with. Not a paused queue the user resolves,
# an app in use, a busy installer, a Store slow to the end but still moving
# ('final', see Get-PreparationStoreTransient), the connection, the wrong account
# or Stop. A failure that usually passes on its own ('retry') gets the repairs
# once Invoke-PreparationStoreWithRetry's tries haven't got past it, as a Store
# that does it every time can be broken.
function Test-PreparationStoreRepairable([Exception]$Exception) {
    if ($Exception -is [OperationCanceledException] -or $Exception -is [System.Net.NetworkInformation.NetworkInformationException]) { return $false }
    if ((Get-PreparationStoreTransient $Exception) -eq 'final') { return $false }
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
        if (Update-PreparationStoreItself -Retry) { Set-PreparationStoreOutcome 'store-updated' }
        Invoke-PreparationStoreWithRetry
        Clear-PreparationStagingRecord
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
# A repair can also say 'skipped', when this PC has nothing to run it with. The
# failure after the last names how each one ended, or the apps of a staging
# failure (see Get-PreparationStagingApp). A staging failure the repairs already
# met in as many runs as they may take stops the run before them.
function Repair-PreparationStore([Exception]$Failure) {
    if ($script:PreparationStoreRepairsRun) { throw $Failure }
    $script:PreparationStoreRepairsRun = $true
    $code = (Get-PreparationFailureDetail $Failure)['errorCode']
    $record = Read-PreparationStagingRecord
    if ($null -ne $record -and $record.Repairs -ge $script:PreparationStagingRepairs) {
        $staging = @(Get-PreparationStagingFailure)
        if (@($staging | Where-Object { $record.Apps -contains $_.Name }).Count -gt 0) {
            $apps = @($staging | ForEach-Object { [string]$_.Name })
            Write-PreparationStoreEvidence ('updating failed ({0}{1}); Windows couldn''t stage updates for {2} again, as in {3} earlier runs whose repairs didn''t help (the last on {4:yyyy-MM-dd}), so they don''t run again' -f
                $Failure.Message, $(if ($code) { ", $code" }), ($apps -join ', '), $record.Repairs, $record.At)
            Save-PreparationStagingRecord @($apps + $record.Apps | Select-Object -Unique) $record.Repairs
            Stop-PreparationStoreStaging $apps $staging "The Store repairs ran in $($record.Repairs) earlier runs without helping, so they didn't run again."
        }
    }
    Write-PreparationStoreEvidence "updating failed ($($Failure.Message)$(if ($code) { ", $code" })); repairing"
    $last = $Failure
    $ended = [Collections.Generic.List[string]]::new()
    # A Store that didn't answer in any of its tries can have a stuck install
    # service, which a restart clears without the repairs.
    $repairs = @($script:PreparationStoreRepairs)
    if ($Failure.Data.Contains('storeSilent')) { $repairs = @('installservice') + $repairs }
    foreach ($repair in $repairs) {
        Assert-PreparationContinue
        Write-PreparationState running store-repair
        try { $result = Invoke-PreparationStoreRepair $repair | Select-Object -Last 1 }
        catch {
            if ($_.Exception -is [OperationCanceledException]) { throw }
            if ($repair -eq 'bootstrap') { Register-PreparationBootstrapStaging $_.Exception }
            $network = if ($_.Exception.Data.Contains('network')) { ', a network problem' } else { '' }
            Write-PreparationStoreEvidence "$repair failed$network`: $($_.Exception.Message)"
            $ended.Add("$repair failed$network")
            continue
        }
        if ($result -is [string] -and $result -ceq 'skipped') {
            Write-PreparationStoreEvidence "$repair skipped"
            $ended.Add("$repair skipped")
            continue
        }
        if (-not [bool]$result) {
            Write-PreparationStoreEvidence "$repair changed nothing"
            $ended.Add("$repair changed nothing")
            continue
        }
        Write-PreparationStoreEvidence "$repair done; trying the Store again"
        try {
            [void](Update-PreparationStoreItself)
            Invoke-PreparationStoreWithRetry
            Set-PreparationStoreOutcome $(if ($repair -eq 'bootstrap' -and $script:PreparationStoreDownloaded) { 'store-bootstrapped' } else { 'store-repaired' })
            Write-PreparationStoreEvidence "works again after $repair"
            Clear-PreparationStagingRecord
            Write-PreparationStoreInventory 'after'
            return
        }
        catch {
            if (-not (Test-PreparationStoreRepairable $_.Exception)) { throw }
            $last = $_.Exception
            Write-PreparationStoreEvidence "still failing after $repair`: $($last.Message)"
            $ended.Add("$repair didn't help")
        }
    }
    Write-PreparationStoreInventory 'after'
    $staging = @(Get-PreparationStagingFailure)
    $apps = @(Get-PreparationStagingApp $staging $last)
    if ($apps.Count -gt 0) {
        # The same apps as a record of an earlier run: one more run whose repairs didn't help.
        $earlier = Read-PreparationStagingRecord
        $runs = if ($null -ne $earlier -and @($earlier.Apps | Where-Object { $apps -contains $_ }).Count -gt 0) { $earlier.Repairs + 1 } else { 1 }
        Save-PreparationStagingRecord $apps $runs
        Write-PreparationStoreEvidence "Windows couldn't stage updates for $($apps -join ', ') (0x80070490), and the repairs didn't help, as recorded for $runs run(s); from $script:PreparationStagingRepairs such runs on, a run doesn't repair again"
        Stop-PreparationStoreStaging $apps $staging "The Store repairs didn't help ($($ended -join '; '))."
    }
    $lastCode = (Get-PreparationFailureDetail $last)['errorCode']
    $hresult = if ($lastCode) { [Convert]::ToInt32($lastCode, 16) } else { 0 }
    throw (New-PreparationFailure "Microsoft Store couldn't be repaired ($($ended -join '; ')): $($last.Message)" 'store-repair-failed' $hresult)
}

function Invoke-PreparationStoreRepair([string]$Repair) {
    switch ($Repair) {
        'installservice' { Restart-PreparationStoreService }
        'wsreset' { Invoke-PreparationWsReset }
        'bootstrap' { Install-PreparationStoreFromMicrosoft }
        'storefixer' { Invoke-PreparationStoreFixer }
    }
}

# Restarts the Microsoft Store Install Service (InstallService), which carries out
# the Store's downloads and installs, for a Store that stopped answering. A service
# that's turned off isn't stopped, as it couldn't start again. Each wait for it is
# cut at a minute, and Stop doesn't interrupt one, so a restart is never left
# between stopping and starting. Returns whether it's running again.
function Restart-PreparationStoreService {
    $service = Get-Service -Name InstallService -ErrorAction Stop
    if ([string]$service.StartType -eq 'Disabled') { throw 'The Microsoft Store Install Service is turned off (start type Disabled).' }
    $was = [string]$service.Status
    if ($was -ne 'Stopped') {
        $service.Stop()
        Wait-PreparationStoreService $service 'Stopped'
    }
    $service.Start()
    Wait-PreparationStoreService $service 'Running'
    Write-PreparationStoreEvidence "installservice: restarted the Microsoft Store Install Service, which was $was"
    return $true
}

function Wait-PreparationStoreService($Service, [string]$Status) {
    for ($waited = 0; $waited -lt 60; $waited += 2) {
        Write-PreparationState running store-repair
        $Service.Refresh()
        if ([string]$Service.Status -eq $Status) { return }
        Start-Sleep -Seconds 2
    }
    throw "The Microsoft Store Install Service isn't $($Status.ToLowerInvariant()) after a minute; it's $($Service.Status)."
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

# A download that the network stopped, named as such: the connection failed or
# was cut, or a proxy or GitHub refused the request. GitHub answers 403 or 429
# when one address sends it too many requests, as a shared or proxied connection
# can, and a proxy that wants credentials answers 407. None of it says anything
# about Microsoft Store.
function New-PreparationNetworkFailure([uri]$Uri, [string]$Problem) {
    $failure = New-PreparationFailure "A network problem stopped the download from $($Uri.Host): $Problem"
    $failure.Data['network'] = $true
    return $failure
}

# Why a download answered with HTTP $Status.
function Get-PreparationHttpFailure([uri]$Uri, [int]$Status) {
    switch ($Status) {
        { $_ -in @(403, 429) } { return (New-PreparationNetworkFailure $Uri "HTTP $Status, which GitHub answers when one address sends it too many requests, and a proxy can answer when it blocks one") }
        407 { return (New-PreparationNetworkFailure $Uri 'HTTP 407: a proxy asks for credentials') }
    }
    return [Exception]::new("Downloading $Uri failed with HTTP status $Status.")
}

# The innermost message of a failed request, which names the network's own error.
function Get-PreparationInnerMessage([Exception]$Exception) {
    $cause = $Exception
    while ($null -ne $cause.InnerException) { $cause = $cause.InnerException }
    return ([string]$cause.Message).Trim()
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
        try { $response = $client.GetAsync($Uri, [Net.Http.HttpCompletionOption]::ResponseHeadersRead).GetAwaiter().GetResult() }
        catch { throw (New-PreparationNetworkFailure $Uri (Get-PreparationInnerMessage $_.Exception)) }
        if (-not $response.IsSuccessStatusCode) { throw (Get-PreparationHttpFailure $Uri ([int]$response.StatusCode)) }
        if ($response.RequestMessage.RequestUri.Scheme -cne 'https') { throw "Downloading $Uri left HTTPS." }
        $stream = $response.Content.ReadAsStreamAsync().GetAwaiter().GetResult()
        $output = [IO.File]::Open($Destination, [IO.FileMode]::CreateNew, [IO.FileAccess]::Write, [IO.FileShare]::None)
        $buffer = New-Object byte[] 65536
        [long]$total = 0
        while ($true) {
            try { $read = $stream.Read($buffer, 0, $buffer.Length) }
            catch { throw (New-PreparationNetworkFailure $Uri (Get-PreparationInnerMessage $_.Exception)) }
            if ($read -le 0) { break }
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

# App Installer staged on this PC, or installed for another account, in a newer
# version than this user has: registering it needs no download. Only package
# versions are compared: Get-AppxPackage -AllUsers lists staged copies too,
# while the provisioned list gives a bundle's version, such as 2026.115.2221.0,
# which is always above App Installer's own 1.x. Returns whether this user's
# version rose, so that when registering changes nothing it is downloaded.
function Register-PreparationNewerAppInstaller {
    $mine = { Get-PreparationAppInstallerVersion }
    $current = & $mine
    $had = if ($null -ne $current) { $current } else { 'none' }
    $newest = @(Get-AppxPackage -AllUsers -Name Microsoft.DesktopAppInstaller -ErrorAction SilentlyContinue |
            Where-Object { [string]$_.PackageFamilyName -ceq $script:PreparationAppInstallerFamily } |
            Sort-Object { [version]$_.Version } -Descending) | Select-Object -First 1
    if ($null -eq $newest -or ($null -ne $current -and $current -ge [version]$newest.Version)) {
        Write-PreparationStoreEvidence "App Installer: this user has $had, and this PC has nothing newer"
        return $false
    }
    # Where the copy is: staged, or which accounts have it, by SID only, as an
    # account's name would reach reports. Not being able to say leaves it out.
    $where = try {
        @($newest.PackageUserInformation | Where-Object { $null -ne $_ } | ForEach-Object { '{0}: {1}' -f $_.UserSecurityId.Sid, $_.InstallState }) -join '; '
    }
    catch { '' }
    Write-PreparationStoreEvidence "App Installer: this user has $had; this PC has $($newest.Version), $($newest.PackageFullName)$(if ($where) { " ($where)" }); registering it"
    Add-AppxPackage -RegisterByFamilyName -MainPackage $script:PreparationAppInstallerFamily -ErrorAction Stop
    $now = & $mine
    if ($null -eq $now -or ($null -ne $current -and $now -le $current)) {
        Write-PreparationStoreEvidence "App Installer: registering the copy this PC has changed nothing; this user has $(if ($null -ne $now) { $now } else { 'none' })"
        return $false
    }
    Write-PreparationStoreEvidence "App Installer: registered the copy this PC has, $had -> $now"
    return $true
}

# App Installer: the newer copy this PC has, when registering it raises this
# user's version, or else one with the frameworks winget-cli's release says it
# needs, from Microsoft's own release; then Microsoft Store itself from the
# Store's catalogue through winget. Downloads go to this job's folder, which
# only administrators can change.
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
        try { [void](Save-PreparationAppInstaller) }
        catch {
            # ERROR_INSTALL_PACKAGE_DOWNGRADE: Windows already has a newer
            # package than the stable release we tried. Use the signed App
            # Installer available to this user, then verify its Store source.
            if ((Get-PreparationHResult $_.Exception) -ne 0x80073D06) { throw }
            Write-PreparationStoreEvidence 'bootstrap: Windows already has a newer App Installer package; trying the installed winget (0x80073D06)'
        }
        $winget = Get-PreparationWingetPath
    }
    Assert-PreparationWingetStoreSource $winget
    $arguments = "install --exact --id $script:PreparationStoreProductId --source msstore --silent --accept-source-agreements --accept-package-agreements --disable-interactivity"
    $exit = Invoke-PreparationStoreProcess $winget $arguments 20 -Hidden
    # 0x8A15002B: nothing newer to install, so the Store is already current.
    Write-PreparationStoreEvidence "bootstrap: winget install of Microsoft Store exited $exit"
    # 0x80072EE0 to 0x80072F8F: WinINet and WinHTTP's own errors, such as a
    # connection cut short (0x80072EFE).
    if ($null -ne $exit -and $exit -ge -2147012896 -and $exit -le -2147012721) {
        throw (New-PreparationNetworkFailure 'https://storeedgefd.dsx.mp.microsoft.com/' ('winget could not install Microsoft Store (exit 0x{0:X8})' -f $exit))
    }
    if ($exit -notin @(0, -1978335189)) { throw "winget couldn't install Microsoft Store (exit $exit)." }
    return $true
}

# This user's App Installer, by the package's own version, or $null.
function Get-PreparationAppInstallerVersion {
    @(Get-AppxPackage -Name Microsoft.DesktopAppInstaller -ErrorAction SilentlyContinue |
            Where-Object { [string]$_.PackageFamilyName -ceq $script:PreparationAppInstallerFamily } |
            ForEach-Object { [version]$_.Version } | Sort-Object -Descending) | Select-Object -First 1
}

# The version this user's winget reports, as in "v1.29.380", or $null.
function Get-PreparationWingetVersion {
    try {
        $winget = Get-PreparationWingetPath
        $output = @(& $winget --version 2>&1 | ForEach-Object { [string]$_ })
        $match = [regex]::Match(($output -join ' '), 'v?(\d+\.\d+\.\d+)')
        if ($LASTEXITCODE -eq 0 -and $match.Success) { return [version]$match.Groups[1].Value }
    }
    catch { Write-PreparationStoreEvidence "bootstrap: winget's version couldn't be read: $($_.Exception.Message)" }
    return $null
}

# Whether this user's App Installer is already the latest stable release or
# newer, so its download would change nothing. The package's own version is
# compared with the release's tag, which names it (see "Microsoft Store repair"
# in docs/preparation.md), and so is the version the user's winget reports. Any
# that's missing or older lets the download go ahead.
function Test-PreparationAppInstallerCurrent($Release) {
    $tag = [regex]::Match([string]$Release.tag_name, '^v?(\d+\.\d+\.\d+)$')
    if (-not $tag.Success) { return $false }
    $latest = [version]$tag.Groups[1].Value
    $installed = Get-PreparationAppInstallerVersion
    if ($null -eq $installed -or [version]('{0}.{1}.{2}' -f $installed.Major, $installed.Minor, $installed.Build) -lt $latest) { return $false }
    $client = Get-PreparationWingetVersion
    if ($null -eq $client -or $client -lt $latest) {
        Write-PreparationStoreEvidence "bootstrap: this user has App Installer $installed, and its winget reports $(if ($null -ne $client) { $client } else { 'no version' }); downloading $($Release.tag_name)"
        return $false
    }
    Write-PreparationStoreEvidence "bootstrap: this user has App Installer $installed with winget $client, at least the latest stable release $($Release.tag_name); not downloading it"
    return $true
}

# App Installer and its frameworks from the latest winget-cli release, unless this
# user already has that release or a newer one. Returns whether it installed them.
function Save-PreparationAppInstaller {
    $folder = Join-Path $JobPath 'store-bootstrap'
    if (Test-Path -LiteralPath $folder) { Remove-Item -LiteralPath $folder -Recurse -Force }
    $null = New-Item -ItemType Directory -Path $folder
    $architecture = switch ($env:PROCESSOR_ARCHITECTURE) { 'AMD64' { 'x64' } 'ARM64' { 'arm64' } 'x86' { 'x86' } }
    if (-not $architecture) { throw "No App Installer frameworks for $env:PROCESSOR_ARCHITECTURE." }
    $release = Get-PreparationWingetRelease $folder
    Write-PreparationStoreEvidence "bootstrap: winget-cli $($release.tag_name)"
    if (Test-PreparationAppInstallerCurrent $release) { return $false }
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
    return $true
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
# is left out there, and says 'skipped'.
function Invoke-PreparationStoreFixer {
    $windows = [Environment]::GetFolderPath('Windows')
    $launcher = [IO.Path]::Combine($windows, 'AtlasModules\Scripts\Entry\Invoke-AtlasToggleLauncher.cmd')
    $definition = [IO.Path]::Combine($windows, 'AtlasModules\Toggles\Troubleshooting\FixMSStoreIssues.psd1')
    $shortcut = [IO.Path]::Combine($windows, 'AtlasDesktop\9. Troubleshooting\Fix MS Store Issues.cmd')
    if (-not ([IO.File]::Exists($launcher) -and [IO.File]::Exists($definition))) {
        Write-PreparationStoreEvidence "StoreFixer: this PC has no Atlas 0.6 Fix MS Store Issues to start it; left out"
        return 'skipped'
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
        # Updates that didn't finish after a restart for them get no other one.
        Write-PreparationLog ($_ | Out-String)
        if (-not $_.Exception.Data.Contains('restartRepeated')) {
            try {
                if (Test-PreparationRestart) { return 'reboot' }
            } catch {
                Write-PreparationLog ($_ | Out-String)
            }
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

# WU_E_WU_DISABLED, WU_E_CALL_CANCELLED_BY_POLICY and ERROR_SERVICE_DISABLED:
# something turned Windows Update off again.
$script:UpdateAccessCodes = @(-2145124306, -2145124305, -2147023838)

# 0x80246017 and 0x80246019: Windows Update refused, within seconds, to download
# a feature update it offered, as it does when it offers one before it has
# taken in the feature-update target.
$script:DownloadRefusedCodes = @(-2145099753, -2145099751)

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
# wins when several do, but never for a title that names another release. Any
# other upgrade is logged and left alone.
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
            if (Test-PreparationOtherReleaseTitle $update) { Write-AtlasTransitionEvidence "unexpected-offer, for another release than $WindowsTarget, not installed: $(Format-PreparationOffer $update)" }
            elseif (Test-PreparationKnownKb $update $FeatureKb) { $known += $update }
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

# After Windows Update refused to download the offer (see $script:DownloadRefusedCodes):
# restarts it, however often the run already has, so it reads the target afresh,
# and waits for its policy state to show the target. The search after this finds
# the offer again for the one more try.
function Reset-PreparationRefusedDownload {
    $why = 'Windows Update refused the download'
    if (-not (Restart-PreparationUpdateService)) {
        Write-AtlasTransitionEvidence "$why; it is busy, so it wasn't restarted"
        return
    }
    $script:PreparationServiceRestarts++
    $read = Wait-PreparationPolicyState
    Write-AtlasTransitionEvidence "$why; restarted wuauserv, policy state now: target '$(Get-PreparationPolicyState)'$(if (-not $read) { " (not the target after $script:PreparationPolicyWaitSeconds seconds)" })"
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
            $hidden = @($offers | Where-Object { -not (Test-PreparationOtherReleaseTitle $_) -and ((Test-PreparationKnownKb $_ $FeatureKb) -or (Test-PreparationTargetTitle $_)) }).Count -gt 0
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
        if ([int]$installed.ResultCode -in @($script:UpdateSucceeded, $script:UpdateSucceededWithErrors) -or $installed.RebootRequired) {
            Set-PreparationInstalled $Journal "update=$($Update.Identity.UpdateID) result=$($installed.ResultCode)" $Update
            return 'installed'
        }
        $failure = [int]$item.HResult
        if ($failure -eq 0) {
            # The result can name no code of its own; the update's history entry has it.
            $failure = Get-PreparationHistoryCode ([string]$Update.Identity.UpdateID)
            Write-AtlasTransitionEvidence ('install {0}: Windows Update history records 0x{1:X8}' -f $label, $failure)
            if ($failure -eq 0) { $failure = [int]$installed.HResult }
        }
    }
    # Another installation held Windows Update: waiting for it doesn't use up the retry.
    if ($failure -eq $script:InstallNotAllowed -and (Wait-PreparationInstallerIdle windows-install)) { return 'busy' }
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
    # A download Windows Update refused gets its one more try after a restart of
    # Windows Update; refused again, the run names the refusal.
    if ($script:DownloadRefusedCodes -contains $failure) {
        if ($MayRetry) { return 'refused' }
        throw (New-AtlasTransitionFailure ("Windows Update refused to download {0} (0x{1:X8}), also after Atlas restarted it and searched again." -f $label, $failure) 'feature-failed' @{ errorCode = '0x{0:X8}' -f $failure })
    }
    if ($MayRetry) { return 'retry' }
    $detail = @{}
    if ($failure -ne 0) { $detail.errorCode = '0x{0:X8}' -f $failure }
    throw (New-AtlasTransitionFailure "Windows could not install $label." 'feature-failed' $detail)
}

# How Windows moved, decided once on the target build and kept in the record:
# switched on in place (the Atlas components are all there), or rebuilt by Setup,
# after which the Atlas install puts Atlas back with the recorded choices. Atlas
# components gone without any sign of Setup is not explained, and stops. A later
# run reads the decision back, never makes it again: an Atlas install since may
# have changed the packages.
function Test-PreparationRebuild($Journal) {
    $decided = Get-AtlasTransitionRebuildDecision $Journal
    if ($decided -eq 'components-lost') {
        throw (New-AtlasTransitionFailure "Atlas components were missing after the update, without a sign of Setup (recorded: $(@($Journal.rebuild.signals) -join ','))." 'feature-components-lost')
    }
    if ($null -ne $decided) { return }
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
    $servicing = Get-PreparationServicingFailure $Journal
    $repeated = Test-PreparationRollbackRepeated $Journal $code $servicing
    # This attempt is over, so the record goes back to before the install: the
    # next run installs the feature update again, and this rollback is counted
    # once, when the next one is compared with it.
    $Journal.phase = 'targeted'
    $Journal | Add-Member -NotePropertyName installed -NotePropertyValue $null -Force
    $Journal | Add-Member -NotePropertyName commitBoot -NotePropertyValue $null -Force
    $Journal | Add-Member -NotePropertyName commitRetried -NotePropertyValue $false -Force
    Write-PreparationJournal $Journal 'rolled-back' ((@($code, $servicing) | Where-Object { $_ }) -join ' ')
    $detail = @{}
    if ($code) { $detail.errorCode = $code }
    $cause = if ($servicing) { " Servicing reported $servicing." } else { '' }
    # The same failure again: trying the same update once more can't help, so the
    # way on is a repair of Windows or a new install, which feature-servicing offers.
    if ($repeated) {
        throw (New-AtlasTransitionFailure "Windows went back to its earlier version again after the restart, the same way as before.$cause Repair Windows, or reinstall it from an Atlas ISO after a backup." 'feature-servicing' $detail)
    }
    throw (New-AtlasTransitionFailure "Windows went back to its earlier version after the restart.$cause" 'feature-rolled-back' $detail)
}

# The servicing log's last failure report for the feature update's own package,
# as in "Package_for_KB5121794~... 0x80070002, failure source AI: System
# Protection luainstall.dll 80070002 31 Delta NONE", or ''. The package is the one
# a KB number of the transition or of the offer names.
function Get-PreparationServicingFailure($Journal) {
    $kbs = @()
    foreach ($name in @('target', 'offer')) {
        $part = $Journal.PSObject.Properties[$name]
        if ($null -ne $part -and $null -ne $part.Value) { $kbs += @([string]$part.Value.kb -split ',') }
    }
    $kbs = @($kbs | Where-Object { $_ -match '^\d{7}$' } | Sort-Object -Unique)
    if ($kbs.Count -eq 0) { return '' }
    try { $lines = @(Get-AtlasTransitionCbsLogTail) }
    catch {
        Write-AtlasTransitionEvidence "the servicing log could not be read: $($_.Exception.Message)"
        return ''
    }
    $report = 'Reporting package change completion for package: (Package_for_KB(\d{7})[^,\s]*), .*?status: (0x[0-9A-Fa-f]{8}), failure source: ([^,]*), failure details: "([^"]*)"'
    for ($index = $lines.Count - 1; $index -ge 0; $index--) {
        $match = [regex]::Match([string]$lines[$index], $report)
        if (-not $match.Success -or $kbs -notcontains $match.Groups[2].Value) { continue }
        $status = [Convert]::ToUInt32($match.Groups[3].Value.Substring(2), 16)
        if ($status -eq 0) { continue }
        $details = ($match.Groups[5].Value -replace '\s+', ' ').Trim()
        $text = '{0} 0x{1:X8}, failure source {2}{3}' -f $match.Groups[1].Value, $status, $match.Groups[4].Value.Trim(), $(if ($details -and $details -ne '(null)') { ": $details" } else { '' })
        return $text.Substring(0, [Math]::Min($text.Length, 300))
    }
    return ''
}

# Whether a rollback repeats one of an earlier install attempt: the same code
# from Windows Update's history and, where both name one, the same servicing
# failure. The open record keeps this move's rollbacks, and the summary of the
# last one closed (LastResult) those of an attempt in the 30 days before. Each
# attempt starts with an 'installed' entry, so only rollbacks before the newest
# one count: those after it are this attempt's own, which a record an earlier
# Atlas left installed can hold several of. A record that no longer has that
# entry can't say which attempt its rollbacks were, and none of them count. A
# rollback that names neither a code nor a failure can't be told apart from
# another.
function Test-PreparationRollbackRepeated($Journal, [string]$Code, [string]$Servicing) {
    if (-not $Code -and -not $Servicing) { return $false }
    $earlier = @()
    if ($null -ne $Journal.PSObject.Properties['history']) {
        $history = @($Journal.history)
        for ($index = $history.Count - 1; $index -ge 0; $index--) {
            $entry = $history[$index]
            if ($null -ne $entry -and $null -ne $entry.PSObject.Properties['event'] -and [string]$entry.event -ceq 'installed') {
                if ($index -gt 0) { $earlier += @($history[0..($index - 1)]) }
                break
            }
        }
    }
    $last = Get-AtlasTransitionValue (Get-AtlasWindowsTransitionRoot) 'LastResult'
    if ($last.Present -and $last.Kind -eq 'String') {
        try {
            $closed = [string]$last.Data | ConvertFrom-Json -ErrorAction Stop
            $at = [DateTime]::MinValue
            if ([DateTime]::TryParse([string]$closed.closedAt, [Globalization.CultureInfo]::InvariantCulture,
                    [Globalization.DateTimeStyles]::AdjustToUniversal, [ref]$at) -and $at -gt [DateTime]::UtcNow.AddDays(-30)) {
                $earlier += @($closed.history)
            }
        }
        catch { Write-AtlasTransitionEvidence "the last closed record could not be read: $($_.Exception.Message)" }
    }
    foreach ($entry in $earlier) {
        if ($null -eq $entry -or $null -eq $entry.PSObject.Properties['event'] -or [string]$entry.event -cne 'rolled-back') { continue }
        $detail = [string]$entry.detail
        $codeBefore = if ($detail -match '^(0x[0-9A-F]{8})\b') { $Matches[1] } else { '' }
        $servicingBefore = ($detail -replace '^0x[0-9A-F]{8}\s*', '').Trim()
        if ($codeBefore -ne $Code) { continue }
        if ($Servicing -and $servicingBefore -and $servicingBefore -ne $Servicing) { continue }
        if (-not $Code -and -not $servicingBefore) { continue }
        return $true
    }
    return $false
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
    $storeRepair = $null
    if ($null -eq $journal -or $journal.kind -eq 'access') {
        if (Test-PreparationRestart) { return 'reboot' }
        # Nothing changes before Windows Update can be reached.
        if (-not (Test-PreparationNetwork)) { throw (New-Object System.Net.NetworkInformation.NetworkInformationException) }
        $storeRepair = Test-AtlasWindowsTransitionPreflight -Wait { Assert-PreparationContinue; Write-PreparationState running windows-repair }
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
    # A feature update can roll back at the restart on a damaged store, so damage
    # other than what the Atlas packages leave is repaired before it. The repair
    # takes its files from Windows Update, so it comes once that is on. Any
    # restart it leaves comes before the monthly updates.
    if ($storeRepair) { [void](Invoke-PreparationComponentRepair $storeRepair -Ahead) }
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
        if ($result -eq 'busy') {
            $attempt--
            continue
        }
        if ($result -eq 'refused') {
            Reset-PreparationRefusedDownload
            continue
        }
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
    # A check waits briefly for another run to finish instead of failing: two Atlas
    # runs, such as an install started while another one checks, can overlap.
    $lockWait = if ($VerifyOnly) { 120000 } else { 0 }
    try { $owned = $mutex.WaitOne($lockWait) } catch [Threading.AbandonedMutexException] { $owned = $true }
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
    Write-PreparationLog (Format-PreparationStop $_ $failureDetail)
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
