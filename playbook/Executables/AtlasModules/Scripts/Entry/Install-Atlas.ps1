<#
.SYNOPSIS
    Installs Atlas from an extracted playbook without AME Wizard.
.DESCRIPTION
    Run from an elevated Windows PowerShell 5.1 prompt inside the extracted playbook:

        .\AtlasModules\Scripts\Entry\Install-Atlas.ps1 -Option defender-enable,
            mitigations-default, auto-updates-disable [-Option ...] [-Unattended] [-Restart]
            [-RestartComment <text>]

    The script checks the machine against playbook.conf, copies the extracted payload
    into a protected staging directory that only Administrators and SYSTEM can write,
    records the requested options there, and hands the install to the TrustedInstaller
    broker in two phases: Capture (begin the install state and record options), then,
    after this process publishes the installing user's identity, Run (commit and execute
    the complete install plan). The same plan, state and identity model that AME drives
    are used; AME is simply not in the loop.
.PARAMETER Option
    FeaturePage option names from playbook.conf. Every required group (Defender,
    mitigations, automatic updates) needs exactly one choice; use Get-AtlasInstallOption
    in the payload module Atlas.InstallState to list them.
.PARAMETER Unattended
    Never prompts. Blocking requirements still apply. Live Windows and Microsoft Store
    checks must confirm preparation is complete before the install plan starts.
.PARAMETER Restart
    Restarts Windows ten seconds after a successful install.
.PARAMETER RestartComment
    The message Windows shows in its restart notice when -Restart is used, so a caller
    in another language can supply its own. Plain text, at most 512 characters; control
    characters are removed. The default is "Atlas installation complete.".
.PARAMETER KeepStaging
    Leaves the protected staging copy in place after a successful install.
.NOTES
    Exit codes: 0 success, 1 install failure, 2 requirements not met, 3 not elevated.
#>
[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)]
    [ValidatePattern('^[a-z0-9-]+$')]
    [string[]]$Option,

    [switch]$Unattended,

    # Retained to explain why legacy SYSTEM setup callers must use the signed-in app.
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

function Test-AtlasDefenderPrepared {
    $base = 'HKLM:\SOFTWARE\Microsoft\Windows Defender'
    $features = Get-ItemProperty -LiteralPath ($base + '\Features') -Name TamperProtection -ErrorAction Stop
    $realTime = Get-ItemProperty -LiteralPath ($base + '\Real-Time Protection') -Name DisableRealtimeMonitoring -ErrorAction Stop
    $spyNet = Get-ItemProperty -LiteralPath ($base + '\SpyNet') -Name SpyNetReporting, SubmitSamplesConsent -ErrorAction Stop
    return ($features.TamperProtection -in @(0,4) -and $realTime.DisableRealtimeMonitoring -eq 1 -and
        $spyNet.SpyNetReporting -eq 0 -and $spyNet.SubmitSamplesConsent -in @(0,2))
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

function Test-AtlasPowerConnected {
    $power = Get-AtlasPowerStatus
    $batteryStatus = [int]$power.BatteryChargeStatus
    if ($batteryStatus -ne 255 -and ($batteryStatus -band 128) -ne 0) { return $true }
    switch ([string]$power.PowerLineStatus) {
        'Online' { return $true }
        'Offline' { return $false }
        default { throw 'Windows could not determine whether AC power is connected.' }
    }
}

function Test-AtlasInstallRequirement {
    <#
    .SYNOPSIS
        Evaluates the machine against the playbook's requirements. Returns objects with
        Name, Passed, Blocking and Detail.
    #>
    param(
        [Parameter(Mandatory = $true)][int[]]$SupportedBuilds,
        [Parameter(Mandatory = $true)][int]$WindowsBuild,
        [int]$WindowsRevision = 0,
        [string]$BuildLabEx = '',
        [AllowEmptyString()][string]$EditionId,
        [AllowEmptyString()][string]$InstallationType,
        [string[]]$DeclaredRequirements = @()
    )

    $results = @()
    foreach ($requirement in $DeclaredRequirements) {
        if ($requirement -notin @('NoAntivirus','PluggedIn','Internet','NoPendingUpdates','DefenderToggled')) {
            throw "Direct installation cannot verify the playbook requirement '$requirement'."
        }
    }
    $results += [pscustomobject]@{
        Name = 'Windows edition'
        Passed = $InstallationType -eq 'Client' -and -not [string]::IsNullOrWhiteSpace($EditionId) -and
            $EditionId -notlike 'Core*' -and $EditionId -notmatch '^(EnterpriseS|EnterpriseSN|EnterpriseSEval|EnterpriseSNEval|IoTEnterpriseS|IoTEnterpriseSK)$'
        Blocking = $true
        Detail = "edition '$EditionId', installation '$InstallationType'; Windows Home, LTSC, IoT LTSC and Server are not supported"
    }
    $results += [pscustomobject]@{
        Name     = 'Windows build'
        Passed   = $SupportedBuilds -contains $WindowsBuild
        Blocking = $true
        Detail   = "build $WindowsBuild; supported: $($SupportedBuilds -join ', ')"
    }
    $release = Get-AtlasWindowsReleaseStatus -Version ([version]("10.0.$WindowsBuild.$WindowsRevision")) -BuildLabEx $BuildLabEx
    $results += [pscustomobject]@{
        Name = 'Windows release'; Passed = $release -eq 'Released'; Blocking = $true
        Detail = if ($release -eq 'Released') { 'a published Windows release' } elseif ($release -eq 'Preview') { 'Insider or preview Windows builds are not supported' } else { 'Windows release could not be verified; connect to the internet and retry with official supported Windows media' }
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
    $sessionManager = Get-ItemProperty -LiteralPath 'HKLM:\SYSTEM\CurrentControlSet\Control\Session Manager' -ErrorAction Stop
    $renameProperty = $sessionManager.PSObject.Properties['PendingFileRenameOperations']
    if ($null -ne $renameProperty -and
        @($renameProperty.Value | Where-Object { -not [string]::IsNullOrWhiteSpace([string]$_) }).Count -gt 0) {
        $pendingReboot = $true
    }
    $results += [pscustomobject]@{
        Name = 'No pending reboot'; Passed = -not $pendingReboot; Blocking = $true
        Detail = 'restart Windows before installing so servicing does not run alongside Atlas'
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
        $thirdPartyAv = @(Get-CimInstance -Namespace 'root\SecurityCenter2' -ClassName AntiVirusProduct -ErrorAction Stop |
            Where-Object { $_.displayName -notlike 'Windows Defender*' -and $_.displayName -notlike 'Microsoft Defender*' } |
            ForEach-Object { $_.displayName })
        $antivirusChecked = $true
        if ($thirdPartyAv.Count -gt 0) { $antivirusDetail = "found: $($thirdPartyAv -join ', ')" }
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
        try { $defenderPassed = Test-AtlasDefenderPrepared }
        catch { $defenderDetail = "Windows Security could not be checked: $($_.Exception.Message)" }
        $results += [pscustomobject]@{ Name='Windows Security'; Passed=$defenderPassed; Blocking=$true; Detail=$defenderDetail }
    }

    return $results
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

    $createWithSecurity = [IO.Directory].GetMethod('CreateDirectory', [type[]]@([string], [Security.AccessControl.DirectorySecurity]))
    if (-not $createWithSecurity) {
        throw 'A protected from-birth staging directory is unavailable in this PowerShell host.'
    }
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
        # Repair the restrictive parent ACL left by an earlier interrupted run.
        [IO.Directory]::SetAccessControl($atlasRoot, $stateSecurity)
    }
    else {
        [void]$createWithSecurity.Invoke($null, [object[]]@([string]$atlasRoot, $stateSecurity.PSObject.BaseObject))
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
        [void]$createWithSecurity.Invoke($null, [object[]]@([string]$stagingRoot, $security.PSObject.BaseObject))
    }
    $payloadRoot = [IO.Path]::Combine($stagingRoot, [guid]::NewGuid().ToString('N'))
    [void]$createWithSecurity.Invoke($null, [object[]]@([string]$payloadRoot, $security.PSObject.BaseObject))
    return $payloadRoot
}

function Copy-AtlasPayloadToStaging {
    <#
    .SYNOPSIS
        Copies the extracted playbook (playbook.conf and the Executables tree) into the
        staging directory, refusing reparse points so a junction cannot redirect the copy.
    #>
    param(
        [Parameter(Mandatory = $true)][string]$ExtractedRoot,
        [Parameter(Mandatory = $true)][string]$StagingRoot
    )

    foreach ($item in Get-ChildItem -LiteralPath $ExtractedRoot -Recurse -Force) {
        if (($item.Attributes -band [IO.FileAttributes]::ReparsePoint) -ne 0) {
            throw "The extracted playbook contains a reparse point at '$($item.FullName)'; refusing to stage it."
        }
    }
    Copy-Item -LiteralPath (Join-Path -Path $ExtractedRoot -ChildPath 'playbook.conf') -Destination (Join-Path -Path $StagingRoot -ChildPath 'playbook.conf') -Force
    Copy-Item -LiteralPath (Join-Path -Path $ExtractedRoot -ChildPath 'Executables') -Destination (Join-Path -Path $StagingRoot -ChildPath 'Executables') -Recurse -Force
    return Join-Path -Path $StagingRoot -ChildPath 'Executables'
}

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

    # The extracted playbook root holds playbook.conf; this script sits under
    # Executables\AtlasModules\Scripts\Entry.
    $extractedRoot = [IO.Path]::GetFullPath([IO.Path]::Combine($scriptsRoot, '..', '..', '..'))
    $playbookPath = Join-Path -Path $extractedRoot -ChildPath 'playbook.conf'
    $targetVersion = Get-AtlasPlaybookVersion -PlaybookPath $playbookPath
    $windowsPath = [Environment]::GetFolderPath('Windows')
    $context = Get-AtlasContext -Refresh

    Write-AtlasInstallStep "Atlas $targetVersion from '$extractedRoot'."
    $mode = Resolve-AtlasInstallMode -TargetVersion $targetVersion -WindowsPath $windowsPath
    Write-AtlasInstallStep "This will be a $mode install."

    $windowsVersion = Get-ItemProperty -LiteralPath 'HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion' -ErrorAction Stop
    [xml]$playbookDocument = [IO.File]::ReadAllText($playbookPath)
    $requirements = @(Test-AtlasInstallRequirement -SupportedBuilds (Get-AtlasPlaybookSupportedBuild -PlaybookPath $playbookPath) `
            -WindowsBuild ([int]$context.WindowsBuild) -EditionId ([string]$windowsVersion.EditionID) `
            -WindowsRevision ([int]$windowsVersion.UBR) -BuildLabEx ([string]$windowsVersion.BuildLabEx) `
            -InstallationType ([string]$windowsVersion.InstallationType) `
            -DeclaredRequirements @(Get-AtlasDeclaredRequirement -Playbook $playbookDocument))
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

    Write-AtlasInstallStep 'Staging the payload in a protected directory...'
    $stagingRoot = New-AtlasProtectedStagingRoot -WindowsPath $windowsPath
    $payloadRoot = Copy-AtlasPayloadToStaging -ExtractedRoot $extractedRoot -StagingRoot $stagingRoot
    Write-AtlasInstallStep 'Verifying Windows and Microsoft Store preparation for the signed-in user...'
    Invoke-AtlasPreparationCheck -PayloadRoot $payloadRoot -JobPath (Join-Path $stagingRoot 'Preparation')
    $request = [pscustomobject]@{ options = @($Option | Sort-Object -Unique) }
    [IO.File]::WriteAllText((Join-Path -Path $payloadRoot -ChildPath 'request.json'), ($request | ConvertTo-Json -Compress), (New-Object Text.UTF8Encoding($false)))

    Write-AtlasInstallStep 'Capturing the install state as TrustedInstaller...'
    $capture = Invoke-AtlasTrustedInstaller -Operation Install -InstallPhase Capture -PayloadRoot $payloadRoot -TimeoutSeconds 300
    if ([int]$capture.ExitCode -ne 0) {
        throw "Install capture failed with exit code $($capture.ExitCode). $($capture.StandardError)"
    }

    Write-AtlasInstallStep 'Publishing the installing user...'
    & (Join-Path -Path $payloadRoot -ChildPath 'AtlasModules\Scripts\Entry\Publish-AtlasInstallUser.ps1') | Out-Null

    Write-AtlasInstallStep 'Running the install plan as TrustedInstaller. This takes several minutes...'
    $run = Invoke-AtlasTrustedInstaller -Operation Install -InstallPhase Run -PayloadRoot $payloadRoot -TimeoutSeconds 7200
    if ([int]$run.ExitCode -ne 0) {
        throw "The install plan failed with exit code $($run.ExitCode). The staging copy at '$stagingRoot' was kept; re-run this script to resume. $($run.StandardError)"
    }

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
    exit 1
}
