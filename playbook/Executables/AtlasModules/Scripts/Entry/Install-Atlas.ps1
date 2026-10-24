<#
.SYNOPSIS
    Installs Atlas from an extracted Atlas package without AME Wizard.
.DESCRIPTION
    Run from an elevated Windows PowerShell 5.1 prompt inside the extracted package:

        .\AtlasModules\Scripts\Entry\Install-Atlas.ps1 -Option defender-enable,
            mitigations-default, auto-updates-disable, keyboard-shortcuts [-Option ...] [-Unattended]
            [-Restart]
            [-RestartComment <text>]

    The script checks the machine against playbook.conf, copies the extracted files
    into a protected staging folder that only Administrators and SYSTEM can write,
    records the requested options there, and hands the install to the TrustedInstaller
    broker in two phases: Capture (begin the install state and record options), then,
    after this process publishes the installing user's identity, Run (commit and execute
    the complete install plan). AME drives the same plan, state and identity model.

    Live Windows Update and Microsoft Store checks must confirm preparation is complete
    before the install plan starts.
.PARAMETER Option
    FeaturePage option names from playbook.conf. Every required group (Defender,
    mitigations, automatic updates, keyboard language switching) needs exactly one
    choice; Get-AtlasPlaybookOption in the Atlas.InstallState module lists each
    group's options.
.PARAMETER Unattended
    Never prompts; blocking requirements still apply.
.PARAMETER WindowsSecurityConfirmed
    The user checked in Windows Security that all four switches are off, so a switch
    whose registry value is missing or unrecognised doesn't block. A switch that reads
    on still does. Atlas Manager passes it when the user confirmed, by hand, the
    reading its final check took.
.PARAMETER Restart
    Restarts Windows ten seconds after a successful install.
.PARAMETER RestartComment
    The message Windows shows in its restart notice when -Restart is used, so a caller
    in another language can supply its own. Plain text, at most 512 characters; control
    characters are removed. The default is "Atlas installation complete.".
.PARAMETER KeepStaging
    Leaves this run's protected staging copy whole. Otherwise a successful install
    removes the copy, and a run that stops before Capture starts (the preparation check
    refused it, or the copy failed) keeps only what diagnostics export. Once Capture has
    started, a failed run keeps its copy until a later successful install tidies it. A
    successful install also removes the package files that earlier attempts' copies
    hold, with or without this switch.
.NOTES
    Exit codes: 0 success, 1 install failure, 2 requirements not met, 3 not elevated,
    5 Windows or Microsoft Store preparation is not current; the install did not start.
    Atlas Manager's launcher reserves 4 for an install that never started.
#>
[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)]
    [ValidatePattern('^[a-z0-9-]+$', Options = [Text.RegularExpressions.RegexOptions]::None)]
    [string[]]$Option,

    [switch]$Unattended,

    [switch]$WindowsSecurityConfirmed,

    # Refused: Store preparation is per user, so setup must run as the signed-in user.
    [switch]$WindowsSetup,

    [switch]$Restart,

    [string]$RestartComment,

    [switch]$KeepStaging
)

$scriptsRoot = [IO.Path]::GetFullPath([IO.Path]::GetDirectoryName($PSScriptRoot))
$bootstrap = [IO.Path]::Combine($scriptsRoot, 'Initialize-AtlasPowerShell.ps1')
if (-not [IO.File]::Exists($bootstrap)) {
    throw "The PowerShell bootstrap is missing at '$bootstrap'."
}
. $bootstrap
. ([IO.Path]::Combine($scriptsRoot, 'Compatibility\Windows-Release.ps1'))

Set-StrictMode -Version 3.0
$ErrorActionPreference = 'Stop'

function Get-AtlasRestartComment {
    <#
    .SYNOPSIS
        The text for shutdown.exe /c: the caller's comment without control characters,
        trimmed and cut to the 512 characters shutdown.exe accepts, or the default.
    #>
    param([string]$Comment)
    $clean = ([string]$Comment -replace '\p{Cc}', ' ').Trim()
    if ([string]::IsNullOrWhiteSpace($clean)) { return 'Atlas installation complete.' }
    if ($clean.Length -gt 512) { $clean = $clean.Substring(0, 512) }
    return $clean
}

function Write-AtlasInstallStep {
    param([Parameter(Mandatory = $true)][string]$Message)
    Write-Host "[Atlas] $Message"
}

function Get-AtlasPowerStatus {
    Add-Type -AssemblyName System.Windows.Forms -ErrorAction Stop
    return [System.Windows.Forms.SystemInformation]::PowerStatus
}

function Get-AtlasDeclaredRequirement([xml]$Playbook) {
    # Development packages may deliberately omit the Requirements element.
    foreach ($node in $Playbook.SelectNodes('/Playbook/Requirements/Requirement')) {
        $node.InnerText
    }
}

function Test-AtlasDefenderPresent {
    # Atlas removes the Defender service together with Defender; a PC where an
    # earlier install did so has no switches to turn off.
    return [bool](Test-Path -LiteralPath 'HKLM:\SYSTEM\CurrentControlSet\Services\WinDefend')
}

function Get-AtlasDefenderSwitch {
    <#
    .SYNOPSIS
        The four Windows Security switches as Off, On or Unknown, in Windows Security's
        order and by the rule Atlas Manager uses; a shared fixture keeps the two in step.
        Reasons maps each Unknown switch to the key or value that stopped the reading.
    .PARAMETER Registry
        Values to read instead of the registry: each key under Windows Defender
        (Features, Real-Time Protection, SpyNet) maps to its values by name, and a key
        that can't be opened is left out. A DWORD is an [int] and a QWORD a [long], as
        the registry returns them; a QWORD counts when it fits in 32 bits, as in Atlas
        Manager.
    .PARAMETER Root
        The hive to read when Registry isn't given, so tests can read keys they own.
    .PARAMETER SubKey
        The Windows Defender key under Root.
    #>
    param(
        [Collections.IDictionary]$Registry,
        [Microsoft.Win32.RegistryKey]$Root = [Microsoft.Win32.Registry]::LocalMachine,
        [string]$SubKey = 'SOFTWARE\Microsoft\Windows Defender'
    )

    if ($null -eq $Registry) {
        $Registry = @{}
        foreach ($name in @('Features', 'Real-Time Protection', 'SpyNet')) {
            $key = try { $Root.OpenSubKey("$SubKey\$name") } catch { $null }
            if ($null -eq $key) { continue }
            try {
                $values = @{}
                foreach ($valueName in $key.GetValueNames()) {
                    $values[$valueName] = $key.GetValue($valueName, $null, [Microsoft.Win32.RegistryValueOptions]::DoNotExpandEnvironmentNames)
                }
                $Registry[$name] = $values
            }
            finally { $key.Dispose() }
        }
    }
    $read = {
        param([string]$Key, [string]$Name)
        $values = $Registry[$Key]
        if ($null -eq $values) { return $null }
        return $values[$Name]
    }
    # The value as the u32 Atlas Manager reads; a negative [int] is a DWORD above 0x7FFFFFFF.
    $dword = {
        param([string]$Key, [string]$Name)
        $number = & $read $Key $Name
        if ($number -is [int]) { return [long]$number -band [uint32]::MaxValue }
        if ($number -is [long] -and $number -ge 0 -and $number -le [uint32]::MaxValue) { return [long]$number }
        return $null
    }
    $realTime = & $dword 'Real-Time Protection' 'DisableRealtimeMonitoring'
    $cloud = & $dword 'SpyNet' 'SpyNetReporting'
    $samples = & $dword 'SpyNet' 'SubmitSamplesConsent'
    $tamper = & $dword 'Features' 'TamperProtection'
    $switches = [ordered]@{
        # 1 turns it off. Without that value Windows has it on, as it does by default.
        RealTimeProtection = if (-not $Registry.Contains('Real-Time Protection')) { 'Unknown' } elseif ($realTime -eq 1) { 'Off' } else { 'On' }
        # 0 is off, 1 basic and 2 advanced.
        CloudDelivered     = if ($null -eq $cloud) { 'Unknown' } elseif ($cloud -eq 0) { 'Off' } else { 'On' }
        # 0 always prompts and 2 never sends; 1 and 3 send automatically.
        SampleSubmission   = if ($samples -in @(0, 2)) { 'Off' } elseif ($samples -in @(1, 3)) { 'On' } else { 'Unknown' }
        TamperProtection   = if ($tamper -in @(0, 4)) { 'Off' } elseif ($tamper -in @(1, 5)) { 'On' } else { 'Unknown' }
    }

    # Each cause of an Unknown switch needs different advice, so the log names it.
    $why = {
        param([string]$Key, [string]$Name)
        if ($null -eq $Registry[$Key]) { return "$Key key missing" }
        $raw = & $read $Key $Name
        if ($null -eq $raw) { return "$Key\$Name missing" }
        $number = & $dword $Key $Name
        if ($null -ne $number) { return "$Key\$Name = $number" }
        if ($raw -is [long]) { return "$Key\$Name is a QWORD that doesn't fit in 32 bits" }
        return "$Key\$Name is a $($raw.GetType().Name), not a DWORD"
    }
    $reasons = @{}
    foreach ($source in @(
            @{ Switch = 'RealTimeProtection'; Key = 'Real-Time Protection'; Name = 'DisableRealtimeMonitoring' }
            @{ Switch = 'CloudDelivered'; Key = 'SpyNet'; Name = 'SpyNetReporting' }
            @{ Switch = 'SampleSubmission'; Key = 'SpyNet'; Name = 'SubmitSamplesConsent' }
            @{ Switch = 'TamperProtection'; Key = 'Features'; Name = 'TamperProtection' }
        )) {
        if ($switches[$source.Switch] -eq 'Unknown') { $reasons[$source.Switch] = & $why $source.Key $source.Name }
    }
    $switches['Reasons'] = $reasons
    return [pscustomobject]$switches
}

function Test-AtlasDefenderPrepared {
    <#
    .SYNOPSIS
        Whether the switches let the install start: every one off or, when the user
        checked Windows Security by hand, none that could be read on.
    #>
    param(
        [Parameter(Mandatory = $true)]$Switch,
        [switch]$Confirmed
    )
    $states = @('RealTimeProtection', 'CloudDelivered', 'SampleSubmission', 'TamperProtection' | ForEach-Object { [string]$Switch.$_ })
    if ($states -contains 'On') { return $false }
    return ($Confirmed -or $states -notcontains 'Unknown')
}

function Invoke-AtlasPreparationCheck([string]$PayloadRoot, [string]$JobPath) {
    [void][IO.Directory]::CreateDirectory($JobPath)
    $worker = Join-Path $PayloadRoot 'AtlasModules\Scripts\Preparation\Update-Windows.ps1'
    $powershell = Join-Path $env:WINDIR 'System32\WindowsPowerShell\v1.0\powershell.exe'
    & $powershell -NoLogo -NoProfile -NonInteractive -ExecutionPolicy Bypass -File $worker -JobPath $JobPath -VerifyOnly `
        > (Join-Path $JobPath 'worker.log')
    if ($LASTEXITCODE -ne 0) { throw "Preparation verification failed. Finish Windows and Store updates in Atlas, then retry. See '$JobPath'." }
    $result = Get-Content -LiteralPath (Join-Path $JobPath 'state.json') -Raw -ErrorAction Stop | ConvertFrom-Json
    if ($result.schema -ne 1 -or $result.status -cne 'complete' -or
        $result.userSid -cne [Security.Principal.WindowsIdentity]::GetCurrent().User.Value) {
        throw 'The preparation provider did not confirm completion for the installing user.'
    }
}

function Test-AtlasPreparationCurrent([string]$PayloadRoot, [string]$JobPath) {
    <#
    .SYNOPSIS
        Whether live Windows and Store checks confirm preparation for the installing
        user. A refusal is reported on stderr so the caller can exit with its own code.
    #>
    try {
        Invoke-AtlasPreparationCheck -PayloadRoot $PayloadRoot -JobPath $JobPath
        return $true
    }
    catch {
        [Console]::Error.WriteLine("[Atlas] $($_.Exception.Message)")
        return $false
    }
}

function Test-AtlasPowerConnected {
    $power = Get-AtlasPowerStatus
    $batteryStatus = [int]$power.BatteryChargeStatus
    # BatteryChargeStatus: 128 = no system battery, 255 = unknown.
    if ($batteryStatus -ne 255 -and ($batteryStatus -band 128) -ne 0) { return $true }
    switch ([string]$power.PowerLineStatus) {
        'Online' { return $true }
        'Offline' { return $false }
        default { throw 'Windows could not determine whether AC power is connected.' }
    }
}

function Test-AtlasUserAccountReady {
    $policy = Get-ItemProperty -LiteralPath 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System' -Name EnableLUA -ErrorAction Stop
    if ($policy.EnableLUA -ne 1) { return $false }
    Initialize-AtlasNativeType
    [Atlas.Native.UserProcess]::ValidateCurrentUserMediumToken()
    return $true
}

function Test-AtlasInstallRequirement {
    <#
    .SYNOPSIS
        Evaluates the machine against the package's requirements. Returns objects with
        Name, Passed, Blocking and Detail.
    #>
    param(
        [Parameter(Mandatory = $true)][int[]]$SupportedBuilds,
        [Parameter(Mandatory = $true)][int]$WindowsBuild,
        [int]$WindowsRevision = 0,
        [string]$BuildLabEx = '',
        [AllowEmptyString()][string]$EditionId,
        [AllowEmptyString()][string]$InstallationType,
        [string[]]$DeclaredRequirements = @(),
        [Security.Principal.SecurityIdentifier]$AccountSid = [Security.Principal.WindowsIdentity]::GetCurrent().User,
        [switch]$WindowsSecurityConfirmed
    )

    $results = @()
    foreach ($requirement in $DeclaredRequirements) {
        if ($requirement -notin @('NoAntivirus','PluggedIn','Internet','NoPendingUpdates','DefenderToggled')) {
            throw "Direct installation cannot verify the package requirement '$requirement'."
        }
    }
    $results += [pscustomobject]@{
        Name = 'Windows edition'
        Passed = $InstallationType -eq 'Client' -and -not [string]::IsNullOrWhiteSpace($EditionId) -and
            $EditionId -notlike 'Core*' -and $EditionId -notmatch '^(EnterpriseS|EnterpriseSN|EnterpriseSEval|EnterpriseSNEval|IoTEnterpriseS|IoTEnterpriseSK)$'
        Blocking = $true
        Detail = "edition '$EditionId', installation '$InstallationType'; Windows Home, LTSC, IoT LTSC and Server are not supported"
    }
    $buildPassed = $SupportedBuilds -contains $WindowsBuild
    $results += [pscustomobject]@{
        Name     = 'Windows build'
        Passed   = $buildPassed
        Blocking = $true
        Detail   = "build $WindowsBuild; supported: $($SupportedBuilds -join ', ')$(if (-not $buildPassed -and $WindowsBuild -in @(26100, 26200)) { '. Atlas Manager can move Windows 11, version 24H2 or 25H2 to a supported version first' })"
    }
    $release = Get-AtlasWindowsReleaseStatus -Version ([version]("10.0.$WindowsBuild.$WindowsRevision")) -BuildLabEx $BuildLabEx
    $results += [pscustomobject]@{
        Name = 'Windows release'; Passed = $release -eq 'Released'; Blocking = $true
        Detail = switch ($release) {
            'Released' { 'a published Windows release' }
            'Preview' { 'Insider or preview Windows builds are not supported' }
            'Unlisted' { "build $WindowsBuild.$WindowsRevision is not in Microsoft's list of public Windows 11 releases; Release Preview and other preview builds are not supported, so check again once Microsoft lists it" }
            default { 'Windows release could not be verified; connect to the internet and retry with official supported Windows media' }
        }
    }

    $accountReady = $false
    $accountDetail = 'Enable User Account Control (UAC), restart Windows, then retry. If using the built-in Administrator account, sign in with another administrator account.'
    # The install plan's per-user steps accept only account SIDs (S-1-5-21-...).
    # Work or school (Microsoft Entra ID) accounts have S-1-12-1 SIDs instead.
    if ($null -eq $AccountSid -or -not $AccountSid.IsAccountSid()) {
        $accountDetail = "Atlas can't be installed from a work or school (Microsoft Entra ID) account. Sign in with a local account or a Microsoft account, then try again."
    }
    else {
        try {
            $accountReady = Test-AtlasUserAccountReady
            if ($accountReady) { $accountDetail = 'UAC is enabled and the account has a normal user token.' }
        }
        catch { $accountDetail += " Account verification failed: $($_.Exception.Message)" }
    }
    $results += [pscustomobject]@{
        Name = 'User account'; Passed = $accountReady; Blocking = $true; Detail = $accountDetail
    }

    $pendingReboot = $false
    foreach ($key in @(
            'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Component Based Servicing\RebootPending'
            'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\WindowsUpdate\Auto Update\RebootRequired'
        )) {
        if (Test-Path -LiteralPath $key -ErrorAction Stop) {
            $pendingReboot = $true
        }
    }
    $results += [pscustomobject]@{
        Name = 'No pending reboot'; Passed = -not $pendingReboot; Blocking = $true
        Detail = 'restart Windows before installing so servicing does not run alongside Atlas'
    }
    # Deferred file replacements without either restart flag are only noted: an
    # update can queue some (printer drivers, for one) without asking for a
    # restart, and apps such as Xbox Gaming Services queue one at every boot.
    $sessionManager = Get-ItemProperty -LiteralPath 'HKLM:\SYSTEM\CurrentControlSet\Control\Session Manager' -ErrorAction Stop
    $renameProperty = $sessionManager.PSObject.Properties['PendingFileRenameOperations']
    $pendingFiles = @()
    if ($null -ne $renameProperty) {
        $entries = @($renameProperty.Value)
        for ($index = 0; $index -lt $entries.Count; $index += 2) {
            $source = [string]$entries[$index]
            if (-not [string]::IsNullOrWhiteSpace($source)) {
                $pendingFiles += ($source.Trim() -replace '^!', '' -replace '^\*\d*', '' -replace '^\\\?\?\\', '')
            }
        }
    }
    $results += [pscustomobject]@{
        Name = 'No pending file replacements'; Passed = $true; Blocking = $false
        Detail = if ($pendingFiles.Count -eq 0) { 'no files are waiting to be replaced at the next restart' } else { "Windows will replace or remove files at the next restart ($(($pendingFiles | Select-Object -First 3) -join ', ')); apps such as Xbox Gaming Services leave this set after every restart" }
    }

    $powerConnected = $false
    $powerDetail = 'connect AC power; the install must not be interrupted'
    try {
        $powerConnected = Test-AtlasPowerConnected
    }
    catch {
        $powerDetail = "power status could not be checked: $($_.Exception.Message)"
    }
    $results += [pscustomobject]@{
        Name = 'Plugged in'; Passed = $powerConnected; Blocking = $DeclaredRequirements -contains 'PluggedIn'
        Detail = $powerDetail
    }

    $thirdPartyAv = @()
    $antivirusChecked = $false
    $antivirusDetail = 'none found'
    try {
        $registrations = @(Get-CimInstance -Namespace 'root\SecurityCenter2' -ClassName AntiVirusProduct -ErrorAction Stop |
            Where-Object { $_.displayName -notlike 'Windows Defender*' -and $_.displayName -notlike 'Microsoft Defender*' })
        # A registration whose signed executable is gone is a leftover of an
        # uninstall (Malwarebytes leaves one); nothing is running to block anything.
        # A registration without a drive or UNC path (a URI, or an unexpanded %variable%
        # path) cannot be verified and counts as installed, as in the app.
        $staleAv = @()
        foreach ($registration in $registrations) {
            $signedExe = ([string]$registration.pathToSignedProductExe).Trim().Trim('"')
            if (-not [string]::IsNullOrWhiteSpace($signedExe) -and $signedExe -match '^(?:[A-Za-z]:|\\\\)' -and
                -not (Test-Path -LiteralPath $signedExe -PathType Leaf)) {
                $staleAv += [string]$registration.displayName
            }
            else {
                $thirdPartyAv += [string]$registration.displayName
            }
        }
        $antivirusChecked = $true
        if ($thirdPartyAv.Count -gt 0) { $antivirusDetail = "found: $($thirdPartyAv -join ', ')" }
        elseif ($staleAv.Count -gt 0) { $antivirusDetail = "none running; a leftover registration for $($staleAv -join ', ') whose files are gone was ignored" }
    }
    catch {
        $antivirusDetail = "antivirus registration could not be checked: $($_.Exception.Message)"
    }
    $results += [pscustomobject]@{
        Name = 'No third-party antivirus'; Passed = $antivirusChecked -and $thirdPartyAv.Count -eq 0
        Blocking = $DeclaredRequirements -contains 'NoAntivirus'
        Detail = $antivirusDetail
    }

    if ($DeclaredRequirements -contains 'DefenderToggled') {
        $defenderPassed = $false
        $defenderDetail = 'turn off the four Windows Security switches shown by Atlas before installation'
        try {
            if (Test-AtlasDefenderPresent) {
                $switches = Get-AtlasDefenderSwitch
                $defenderPassed = Test-AtlasDefenderPrepared -Switch $switches -Confirmed:$WindowsSecurityConfirmed
                $labels = [ordered]@{ RealTimeProtection = 'real-time protection'; CloudDelivered = 'cloud-delivered protection'; SampleSubmission = 'automatic sample submission'; TamperProtection = 'Tamper Protection' }
                $on = @($labels.Keys | Where-Object { $switches.$_ -eq 'On' } | ForEach-Object { $labels[$_] })
                $reasonsProperty = $switches.PSObject.Properties['Reasons']
                $reasons = if ($null -ne $reasonsProperty -and $null -ne $reasonsProperty.Value) { $reasonsProperty.Value } else { @{} }
                $unreadable = @($labels.Keys | Where-Object { $switches.$_ -eq 'Unknown' } | ForEach-Object {
                        if ($reasons.Contains($_)) { "$($labels[$_]) ($($reasons[$_]))" } else { $labels[$_] }
                    })
                if ($defenderPassed -and $unreadable.Count -eq 0) {
                    $defenderDetail = 'all four switches are off'
                }
                elseif ($defenderPassed) {
                    $defenderDetail = "the switches that could be read are off, and the user confirmed in Windows Security that the rest are too: $($unreadable -join ', ')"
                }
                else {
                    if ($on.Count -gt 0) { $defenderDetail += "; on: $($on -join ', ')" }
                    if ($unreadable.Count -gt 0) { $defenderDetail += "; couldn't be read: $($unreadable -join ', ')" }
                    if ($on.Count -eq 0) { $defenderDetail += '. If Windows Security shows them off, run again with -WindowsSecurityConfirmed' }
                }
            }
            else {
                $defenderPassed = $true
                $defenderDetail = 'Microsoft Defender is not installed on this PC; an earlier Atlas install removed it, so there is nothing to turn off'
            }
        }
        catch { $defenderDetail = "Windows Security could not be checked: $($_.Exception.Message)" }
        $results += [pscustomobject]@{ Name='Windows Security'; Passed=$defenderPassed; Blocking=$true; Detail=$defenderDetail }
    }

    return $results
}

function Test-AtlasWindowsUpdateInProgress {
    <#
    .SYNOPSIS
        Blocks while Atlas Manager is moving Windows to another release, or when its
        record of the Windows Update settings it changed cannot be read. Windows Update
        settings turned on for plain updates are put back by this install's last steps.
    #>
    param([Parameter(Mandatory = $true)][int]$WindowsBuild)

    $open = Test-AtlasWindowsTransitionOpen
    $passed = $true
    $detail = 'Atlas Manager is not updating Windows'
    if ($null -ne $open -and -not $open.Readable) {
        $passed = $false
        $detail = "Atlas Manager's record of the Windows Update settings it changed cannot be read: $($open.Error)"
    }
    elseif ($null -ne $open -and $open.Kind -eq 'transition' -and $WindowsBuild -ne $open.TargetBuild) {
        $passed = $false
        $detail = "Atlas Manager is moving Windows to build $($open.TargetBuild); finish or stop that in Atlas Manager first"
    }
    # Whether Windows rebuilt itself decides the install mode, so the install
    # waits until Atlas Manager has checked.
    elseif ($null -ne $open -and $open.Kind -eq 'transition' -and $null -eq $open.Rebuild) {
        $passed = $false
        $detail = 'Atlas Manager has not checked how Windows moved yet; continue updating in Atlas Manager first'
    }
    elseif ($null -ne $open -and $open.Kind -eq 'transition' -and $open.Rebuild -eq 'components-lost') {
        $passed = $false
        $detail = 'Atlas packages are gone after the Windows update without Windows reinstalling itself; send a report from Atlas Manager'
    }
    elseif ($null -ne $open) {
        $detail = 'the Windows Update settings Atlas Manager turned on are put back at the end of this install'
    }
    return [pscustomobject]@{ Name = 'No Windows update in progress'; Passed = $passed; Blocking = $true; Detail = $detail }
}

function New-AtlasFrontDoorDirectorySecurity {
    param([switch]$ReadableState)
    $security = New-Object Security.AccessControl.DirectorySecurity
    $security.SetOwner((New-Object Security.Principal.SecurityIdentifier('S-1-5-32-544')))
    $security.SetAccessRuleProtection($true, $false)
    $inheritance = [Security.AccessControl.InheritanceFlags]::ContainerInherit -bor [Security.AccessControl.InheritanceFlags]::ObjectInherit
    foreach ($sid in @('S-1-5-18', 'S-1-5-32-544')) {
        $security.AddAccessRule((New-Object Security.AccessControl.FileSystemAccessRule(
                    (New-Object Security.Principal.SecurityIdentifier($sid)),
                    [Security.AccessControl.FileSystemRights]::FullControl,
                    $inheritance,
                    [Security.AccessControl.PropagationFlags]::None,
                    [Security.AccessControl.AccessControlType]::Allow
                )))
    }

    if ($ReadableState) {
        $security.AddAccessRule((New-Object Security.AccessControl.FileSystemAccessRule(
                (New-Object Security.Principal.SecurityIdentifier('S-1-5-32-545')),
                [Security.AccessControl.FileSystemRights]::ReadAndExecute,
                $inheritance,
                [Security.AccessControl.PropagationFlags]::None,
                [Security.AccessControl.AccessControlType]::Allow
            )))
    }
    return $security
}

function New-AtlasProtectedStagingRoot {
    <#
    .SYNOPSIS
        Creates a unique directory beneath the protected staging root with a from-birth
        DACL that only SYSTEM and Administrators can write.
    #>
    param([Parameter(Mandatory = $true)][string]$WindowsPath)

    $security = New-AtlasFrontDoorDirectorySecurity
    # Create the shared state parent separately. CreateDirectory(path, security)
    # also stamps missing ancestors: using the staging ACL for AtlasOS would
    # make active.json and state.json unreadable to desktop/user setup commands.
    $atlasRoot = [IO.Path]::Combine($WindowsPath, 'AtlasOS')
    $stateSecurity = New-AtlasFrontDoorDirectorySecurity -ReadableState
    if ([IO.Directory]::Exists($atlasRoot)) {
        if (([IO.File]::GetAttributes($atlasRoot) -band [IO.FileAttributes]::ReparsePoint) -ne 0) {
            throw "The Atlas state root '$atlasRoot' must not be a reparse point."
        }
        # Repairs the restrictive ACL that pre-release builds of this script gave
        # AtlasOS by creating Staging first. Remove once no such machine remains.
        [IO.Directory]::SetAccessControl($atlasRoot, $stateSecurity)
    }
    else {
        [void][IO.Directory]::CreateDirectory($atlasRoot, $stateSecurity)
    }

    # Existing children can retain the old inherited ACL after SetAccessControl.
    # Repair the shared install directory and its atomic state files explicitly.
    $installRoot = [IO.Path]::Combine($atlasRoot, 'Install')
    if ([IO.Directory]::Exists($installRoot)) {
        if (([IO.File]::GetAttributes($installRoot) -band [IO.FileAttributes]::ReparsePoint) -ne 0) {
            throw "The Atlas install-state root '$installRoot' must not be a reparse point."
        }
        [IO.Directory]::SetAccessControl($installRoot, $stateSecurity)
        foreach ($name in @('active.json', 'active.json.bak')) {
            $stateFile = [IO.Path]::Combine($installRoot, $name)
            if (-not [IO.File]::Exists($stateFile)) { continue }
            if (([IO.File]::GetAttributes($stateFile) -band [IO.FileAttributes]::ReparsePoint) -ne 0) {
                throw "The Atlas install-state file '$stateFile' must not be a reparse point."
            }
            $fileSecurity = [IO.File]::GetAccessControl($stateFile)
            $fileSecurity.AddAccessRule((New-Object Security.AccessControl.FileSystemAccessRule(
                        (New-Object Security.Principal.SecurityIdentifier('S-1-5-32-545')),
                        [Security.AccessControl.FileSystemRights]::Read,
                        [Security.AccessControl.AccessControlType]::Allow
                    )))
            [IO.File]::SetAccessControl($stateFile, $fileSecurity)
        }
    }

    $stagingRoot = [IO.Path]::Combine($atlasRoot, 'Staging')
    if (-not [IO.Directory]::Exists($stagingRoot)) {
        [void][IO.Directory]::CreateDirectory($stagingRoot, $security)
    }
    $payloadRoot = [IO.Path]::Combine($stagingRoot, [guid]::NewGuid().ToString('N'))
    [void][IO.Directory]::CreateDirectory($payloadRoot, $security)
    return $payloadRoot
}

function Copy-AtlasPayloadToStaging {
    <#
    .SYNOPSIS
        Copies the extracted package (playbook.conf and the Executables tree) into the
        staging folder, refusing links and junctions so none can redirect the copy.
    #>
    param(
        [Parameter(Mandatory = $true)][string]$ExtractedRoot,
        [Parameter(Mandatory = $true)][string]$StagingRoot
    )

    foreach ($item in Get-ChildItem -LiteralPath $ExtractedRoot -Recurse -Force) {
        # Mount points report LinkType Junction too. Other reparse points, such as
        # OneDrive Files On-Demand placeholders, hold their own data.
        if (($item.Attributes -band [IO.FileAttributes]::ReparsePoint) -ne 0 -and @('SymbolicLink', 'Junction') -contains $item.LinkType) {
            throw "The extracted package contains a link or junction (a reparse point that redirects) at '$($item.FullName)'; refusing to copy it."
        }
    }
    Copy-Item -LiteralPath (Join-Path -Path $ExtractedRoot -ChildPath 'playbook.conf') -Destination (Join-Path -Path $StagingRoot -ChildPath 'playbook.conf') -Force
    Copy-Item -LiteralPath (Join-Path -Path $ExtractedRoot -ChildPath 'Executables') -Destination (Join-Path -Path $StagingRoot -ChildPath 'Executables') -Recurse -Force
    return Join-Path -Path $StagingRoot -ChildPath 'Executables'
}

function Remove-AtlasStagedPackage {
    <#
    .SYNOPSIS
        Removes the package files from a staging copy and keeps what diagnostics
        export: request.json, AtlasModules\Logs and the Preparation folder.
    #>
    param([Parameter(Mandatory = $true)][string]$StagingRoot)

    Remove-Item -LiteralPath ([IO.Path]::Combine($StagingRoot, 'playbook.conf')) -Force -ErrorAction SilentlyContinue
    foreach ($item in @(Get-ChildItem -LiteralPath ([IO.Path]::Combine($StagingRoot, 'Executables')) -Force -ErrorAction SilentlyContinue)) {
        if ($item.Name -eq 'request.json') { continue }
        if ($item.Name -eq 'AtlasModules' -and $item.PSIsContainer) {
            Get-ChildItem -LiteralPath $item.FullName -Force -ErrorAction SilentlyContinue | Where-Object { $_.Name -ne 'Logs' } |
                Remove-Item -Recurse -Force -ErrorAction SilentlyContinue
            continue
        }
        Remove-Item -LiteralPath $item.FullName -Recurse -Force -ErrorAction SilentlyContinue
    }
}

function Remove-AtlasEarlierStagedPackage {
    <#
    .SYNOPSIS
        After a successful install, removes the package files that earlier attempts'
        staging copies hold, keeping their evidence. Copies made after this run's are
        left alone in case another run is still using one.
    #>
    param([Parameter(Mandatory = $true)][string]$StagingRoot)

    try {
        $created = [IO.Directory]::GetCreationTimeUtc($StagingRoot)
        foreach ($copy in @(Get-ChildItem -LiteralPath ([IO.Path]::GetDirectoryName($StagingRoot)) -Directory -Force -ErrorAction SilentlyContinue)) {
            if ($copy.CreationTimeUtc -ge $created -or ($copy.Attributes -band [IO.FileAttributes]::ReparsePoint) -ne 0) { continue }
            Remove-AtlasStagedPackage -StagingRoot $copy.FullName
        }
    }
    catch {
        Write-Warning -WarningAction Continue -Message "Earlier staging copies could not be tidied: $($_.Exception.Message)"
    }
}

function Invoke-AtlasInstallPhase {
    <#
    .SYNOPSIS
        Runs one install phase through the TrustedInstaller broker. A failure keeps the
        broker's message, which ends with the phase log, and puts what to do next last
        so it stays on screen.
    #>
    param(
        [Parameter(Mandatory = $true)][ValidateSet('Capture', 'Run')][string]$Phase,
        [Parameter(Mandatory = $true)][string]$PayloadRoot,
        [Parameter(Mandatory = $true)][int]$TimeoutSeconds
    )

    try {
        $null = Invoke-AtlasTrustedInstaller -Operation Install -InstallPhase $Phase -PayloadRoot $PayloadRoot -TimeoutSeconds $TimeoutSeconds
    }
    catch {
        $log = [IO.Path]::Combine($PayloadRoot, 'AtlasModules', 'Logs', "install-$($Phase.ToLowerInvariant()).log")
        if ($Phase -eq 'Capture') {
            throw "Install capture failed: $($_.Exception.Message) The full log is '$log'. Re-run this script with the same options to try again."
        }
        throw "The install plan failed: $($_.Exception.Message) The full log is '$log'. Re-run this script with the same options to resume."
    }
}

$stagingRoot = $null
$brokerStarted = $false
try {
    Import-Module -Name (Join-Path -Path $scriptsRoot -ChildPath 'Modules\Atlas.Core\Atlas.Core.psd1') -Force -ErrorAction Stop
    Import-Module -Name (Join-Path -Path $scriptsRoot -ChildPath 'Modules\Atlas.InstallState\Atlas.InstallState.psd1') -Force -DisableNameChecking -ErrorAction Stop

    if (-not (Test-AtlasAdmin)) {
        [Console]::Error.WriteLine('Install-Atlas.ps1 must run from an elevated Windows PowerShell prompt.')
        exit 3
    }

    if ($WindowsSetup) {
        throw 'WindowsSetup cannot verify per-user Microsoft Store preparation. Finish setup and run Atlas as the signed-in user.'
    }

    # The extracted package root holds playbook.conf; this script sits under
    # Executables\AtlasModules\Scripts\Entry.
    $extractedRoot = [IO.Path]::GetFullPath([IO.Path]::Combine($scriptsRoot, '..', '..', '..'))
    $playbookPath = Join-Path -Path $extractedRoot -ChildPath 'playbook.conf'
    $targetVersion = Get-AtlasPlaybookVersion -PlaybookPath $playbookPath
    $windowsPath = [Environment]::GetFolderPath('Windows')
    $context = Get-AtlasContext -Refresh

    Write-AtlasInstallStep "Atlas $targetVersion from '$extractedRoot'."
    . (Join-Path -Path $scriptsRoot -ChildPath 'Preparation\WindowsTransition.ps1')

    $windowsVersion = Get-ItemProperty -LiteralPath 'HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion' -ErrorAction Stop
    [xml]$playbookDocument = [IO.File]::ReadAllText($playbookPath)
    $requirements = @(Test-AtlasInstallRequirement -SupportedBuilds (Get-AtlasPlaybookSupportedBuild -PlaybookPath $playbookPath) `
            -WindowsBuild ([int]$context.WindowsBuild) -EditionId ([string]$windowsVersion.EditionID) `
            -WindowsRevision ([int]$windowsVersion.UBR) -BuildLabEx ([string]$windowsVersion.BuildLabEx) `
            -InstallationType ([string]$windowsVersion.InstallationType) `
            -DeclaredRequirements @(Get-AtlasDeclaredRequirement -Playbook $playbookDocument) `
            -WindowsSecurityConfirmed:$WindowsSecurityConfirmed)
    $requirements += Test-AtlasWindowsUpdateInProgress -WindowsBuild ([int]$context.WindowsBuild)
    $blocked = $false
    foreach ($requirement in $requirements) {
        if ($requirement.Passed) {
            Write-AtlasInstallStep "OK   $($requirement.Name) ($($requirement.Detail))"
            continue
        }
        if ($requirement.Blocking) {
            Write-AtlasInstallStep "FAIL $($requirement.Name) ($($requirement.Detail))"
            $blocked = $true
        }
        else {
            Write-AtlasInstallStep "WARN $($requirement.Name): $($requirement.Detail)"
        }
    }
    if ($blocked) {
        exit 2
    }
    $warnings = @($requirements | Where-Object { -not $_.Passed })
    if ($warnings.Count -gt 0 -and -not $Unattended) {
        if ((Read-Host 'Continue despite the warnings above? [Y/N]') -notmatch '^(y|yes)$') {
            exit 2
        }
    }
    # After the requirements, so a Windows version Atlas does not support is
    # reported as such rather than as an Atlas version it cannot update.
    $mode = Resolve-AtlasInstallMode -TargetVersion $targetVersion -WindowsPath $windowsPath
    Write-AtlasInstallStep "Install mode: $mode."

    Write-AtlasInstallStep 'Copying Atlas''s files to a protected folder...'
    $stagingRoot = New-AtlasProtectedStagingRoot -WindowsPath $windowsPath
    $payloadRoot = Copy-AtlasPayloadToStaging -ExtractedRoot $extractedRoot -StagingRoot $stagingRoot
    Write-AtlasInstallStep 'Verifying Windows and Microsoft Store preparation for the signed-in user...'
    # A distinct exit code lets Atlas Manager send the user back to preparation.
    if (-not (Test-AtlasPreparationCurrent -PayloadRoot $payloadRoot -JobPath (Join-Path $stagingRoot 'Preparation'))) {
        if (-not $KeepStaging) { Remove-AtlasStagedPackage -StagingRoot $stagingRoot }
        exit 5
    }
    $request = [pscustomobject]@{ options = @($Option | Sort-Object -Unique) }
    [IO.File]::WriteAllText((Join-Path -Path $payloadRoot -ChildPath 'request.json'), ($request | ConvertTo-Json -Compress), (New-Object Text.UTF8Encoding($false)))

    Write-AtlasInstallStep 'Capturing the install state as TrustedInstaller...'
    $brokerStarted = $true
    Invoke-AtlasInstallPhase -Phase Capture -PayloadRoot $payloadRoot -TimeoutSeconds 300

    Write-AtlasInstallStep 'Publishing the installing user...'
    & (Join-Path -Path $payloadRoot -ChildPath 'AtlasModules\Scripts\Entry\Publish-AtlasInstallUser.ps1') | Out-Null

    Write-AtlasInstallStep 'Running the install plan as TrustedInstaller. This takes several minutes...'
    Invoke-AtlasInstallPhase -Phase Run -PayloadRoot $payloadRoot -TimeoutSeconds 7200

    Remove-AtlasEarlierStagedPackage -StagingRoot $stagingRoot
    if (-not $KeepStaging) {
        Remove-Item -LiteralPath $stagingRoot -Recurse -Force -ErrorAction SilentlyContinue
    }
    Write-AtlasInstallStep 'Atlas installed successfully.'
    if ($Restart) {
        Write-AtlasInstallStep 'Restarting in ten seconds.'
        & (Join-Path -Path $windowsPath -ChildPath 'System32\shutdown.exe') /r /t 10 /c (Get-AtlasRestartComment -Comment $RestartComment)
    }
    else {
        Write-AtlasInstallStep 'Restart Windows to finish.'
    }
    exit 0
}
catch {
    [Console]::Error.WriteLine("[Atlas] $($_.Exception.Message)")
    # A broker that timed out may leave its TrustedInstaller child in the copy, so
    # once one has started, the next successful install tidies the copy instead.
    if ($null -ne $stagingRoot -and -not $brokerStarted -and -not $KeepStaging) {
        Remove-AtlasStagedPackage -StagingRoot $stagingRoot
    }
    exit 1
}
