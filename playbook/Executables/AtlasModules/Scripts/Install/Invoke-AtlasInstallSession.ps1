<#
.SYNOPSIS
    TrustedInstaller half of the Atlas front door.
.DESCRIPTION
    Entry\Install-Atlas.ps1 stages the extracted package beneath the protected staging
    root and asks the TrustedInstaller broker to run this script from that copy, twice:

      -Phase Capture   Reads request.json beside the staged files, decides Fresh, Upgrade,
                       Reapply or Rebase from the machine state document, begins the
                       install state and records the validated options. An update that
                       keeps the choices records them as the PC has them. The front
                       door then publishes the installing user's marker from its own
                       session.
      -Phase Run       Binds the published user, commits the captured state and runs the
                       complete install plan through Entry\Invoke-AtlasInstall.ps1.

    request.json is a size-limited document:
    { "options": [ "<option>", ... ], "choices": "Keep" | "ChooseAgain" }. Every option
    must be declared by playbook.conf, every required option group must be satisfied,
    and nothing else is accepted. The broker has already verified that this script and
    its staging root are owned and writable only by trusted principals.

    Each phase leaves a copy of its log under the machine's Logs\install folder,
    whether it succeeds or fails, because this staging copy goes once an install
    succeeds and only administrators can read it.
.NOTES
    Exit codes: 0 success, 1 failure, 2 wrong privilege.
#>
[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)]
    [ValidateSet('Capture', 'Run')]
    [string]$Phase
)

$scriptsRoot = [IO.Path]::GetFullPath([IO.Path]::GetDirectoryName($PSScriptRoot))
$bootstrap = [IO.Path]::Combine($scriptsRoot, 'Initialize-AtlasPowerShell.ps1')
$sessionLog = [IO.Path]::Combine([IO.Path]::GetDirectoryName($scriptsRoot), 'Logs', "install-$($Phase.ToLowerInvariant()).log")

function Write-AtlasSessionLog {
    param([string]$Message)
    [IO.File]::AppendAllText($sessionLog, "[$([DateTime]::UtcNow.ToString('o'))] $Message`r`n", [Text.UTF8Encoding]::new($false))
}

function Save-AtlasSessionLog {
    <#
    .SYNOPSIS
        Copies this phase's log, as it stands, beside the machine's other install logs
        as <UTC yyyyMMdd-HHmmss>-install-<phase>.log. Best effort: the phase's own
        outcome is what gets reported, so a failed copy is only noted in the log.
    #>
    param(
        [string]$LogPath = $sessionLog,
        [string]$PhaseName = $Phase,
        [string]$LogRoot = [IO.Path]::Combine([Environment]::GetFolderPath('Windows'), 'AtlasModules', 'Logs'),
        [DateTime]$Now = [DateTime]::UtcNow
    )

    try {
        if (-not [IO.File]::Exists($LogPath)) { return }
        # A reparse point would send the copy wherever it points.
        foreach ($folder in @($LogRoot, [IO.Path]::Combine($LogRoot, 'install'))) {
            if ([IO.Directory]::Exists($folder) -and ([IO.File]::GetAttributes($folder) -band [IO.FileAttributes]::ReparsePoint) -ne 0) {
                throw "'$folder' is a reparse point."
            }
        }
        $installLogs = [IO.Directory]::CreateDirectory([IO.Path]::Combine($LogRoot, 'install')).FullName
        $copy = [IO.Path]::Combine($installLogs, ('{0:yyyyMMdd-HHmmss}-install-{1}.log' -f $Now.ToUniversalTime(), $PhaseName.ToLowerInvariant()))
        [IO.File]::Copy($LogPath, $copy, $true)
    }
    catch {
        try { Write-AtlasSessionLog "Couldn't copy this log to the machine's Logs folder: $($_.Exception.Message)" }
        catch { $null = $_ }
    }
}

Set-StrictMode -Version 3.0
$ErrorActionPreference = 'Stop'

function Read-AtlasInstallRequest {
    <#
    .SYNOPSIS
        Reads request.json: the options, and how an update treats the choices the PC
        has (Keep unless it says ChooseAgain).
    #>
    param([Parameter(Mandatory = $true)][string]$PayloadRoot)

    $requestPath = Join-Path -Path $PayloadRoot -ChildPath 'request.json'
    if (-not [IO.File]::Exists($requestPath)) {
        throw "The install request '$requestPath' is missing."
    }
    if ((Get-Item -LiteralPath $requestPath).Length -gt 65536) {
        throw 'The install request exceeds its size limit.'
    }
    $request = [IO.File]::ReadAllText($requestPath) | ConvertFrom-Json -ErrorAction Stop
    foreach ($property in $request.PSObject.Properties) {
        if ($property.Name -cnotin @('options', 'choices')) {
            throw "The install request has an unknown field '$($property.Name)'."
        }
    }
    if ($null -eq $request.PSObject.Properties['options']) {
        throw "The install request declares no 'options'."
    }
    $choices = 'Keep'
    $requestedChoices = $request.PSObject.Properties['choices']
    if ($null -ne $requestedChoices) {
        if ($requestedChoices.Value -isnot [string] -or $requestedChoices.Value -cnotin @('Keep', 'ChooseAgain')) {
            throw "The install request's choices must be 'Keep' or 'ChooseAgain', not '$($requestedChoices.Value)'."
        }
        $choices = [string]$requestedChoices.Value
    }
    return [pscustomobject]@{
        Options = @($request.options | ForEach-Object { [string]$_ })
        Choices = $choices
    }
}

function Assert-AtlasInstallOptionSet {
    <#
    .SYNOPSIS
        Rejects unknown options and unsatisfied option groups; returns the option set.
    .PARAMETER ResumedOptions
        The options of the unfinished install this request resumes. A resume must
        keep them, so a required group added to the package after they were
        recorded may stay unchosen when they chose nothing in it; its steps then
        change nothing.
    #>
    param(
        [Parameter(Mandatory = $true)][AllowEmptyCollection()][string[]]$Options,
        [Parameter(Mandatory = $true)][object[]]$Groups,
        [AllowEmptyCollection()][string[]]$ResumedOptions
    )

    $known = @($Groups | ForEach-Object { $_.Options })
    foreach ($option in $Options) {
        if ($known -cnotcontains $option) {
            throw "Option '$option' is not declared by playbook.conf."
        }
    }
    if (@($Options | Sort-Object -Unique).Count -ne $Options.Count) {
        throw 'The install request repeats an option.'
    }
    foreach ($group in $Groups) {
        $chosen = @($Options | Where-Object { $group.Options -ccontains $_ })
        if (-not [string]::IsNullOrWhiteSpace([string]$group.DependsOn) -and $Options -cnotcontains [string]$group.DependsOn) {
            if ($chosen.Count -gt 0) {
                throw "Options $($chosen -join ', ') require '$($group.DependsOn)'."
            }
            continue
        }
        $addedSinceResumed = $chosen.Count -eq 0 -and $PSBoundParameters.ContainsKey('ResumedOptions') -and
            -not @($ResumedOptions | Where-Object { $group.Options -ccontains $_ })
        if ($group.ExactlyOne -and $chosen.Count -ne 1 -and -not $addedSinceResumed) {
            throw "Exactly one of $($group.Options -join ', ') must be selected."
        }
    }
    return $Options
}

function Invoke-AtlasInstallCapture {
    <#
    .SYNOPSIS
        Begins the install state for request.json and records its options, logging
        each decision, and returns the line that says what it captured. An update
        from an Atlas older than 0.6 first rewrites the toggle records it left, and
        an update that keeps the choices records the ones this PC shows. A run whose
        steps began keeps the way and the options it began with, so neither happens
        to it again.
    #>
    param(
        [Parameter(Mandatory = $true)][string]$PlaybookPath,
        [Parameter(Mandatory = $true)][string]$PayloadRoot
    )

    $targetVersion = Get-AtlasPlaybookVersion -PlaybookPath $PlaybookPath
    $request = Read-AtlasInstallRequest -PayloadRoot $PayloadRoot
    $groups = @(Get-AtlasPlaybookOption -PlaybookPath $PlaybookPath)
    $mode = Resolve-AtlasInstallMode -TargetVersion $targetVersion
    # Refuses -ChooseAgain on a Rebase before anything changes.
    $updatePath = Resolve-AtlasInstallChoices -TargetVersion $targetVersion -Mode $mode -Requested $request.Choices
    Write-AtlasSessionLog "Install mode: $($updatePath.Summary)."
    if ($updatePath.Note) { Write-AtlasSessionLog $updatePath.Note }
    # Held to the options it began with, as Set-AtlasInstallOptions holds it.
    $held = $null -ne $updatePath.ResumedOptions
    $optionCheck = @{ Options = @($request.Options); Groups = $groups }
    if ($held) {
        $optionCheck.ResumedOptions = @($updatePath.ResumedOptions)
    }
    $options = Assert-AtlasInstallOptionSet @optionCheck

    if (-not $held -and $mode -cin @('Upgrade', 'Reapply', 'Rebase')) {
        # Before anything reads the records, and once: a run whose steps began
        # has already rewritten them, and its legacy choices step has since
        # removed the launcher paths these rules go by.
        foreach ($line in @(Repair-AtlasToolboxRecord -InstalledVersion (Get-AtlasInstalledVersion))) {
            Write-AtlasSessionLog $line
        }
    }
    # A Rebase is never read from the PC: a rebuilt Windows no longer shows its
    # choices, so the record of the move keeps them.
    if (-not $held -and $updatePath.Choices -ceq 'Keep' -and $mode -cin @('Upgrade', 'Reapply')) {
        $kept = Resolve-AtlasKeptOption -Requested $options
        foreach ($warning in @($kept.Warnings)) { Write-AtlasSessionLog "WARNING: $warning" }
        foreach ($change in @($kept.Changes)) { Write-AtlasSessionLog ([string]$change.Message) }
        $options = Assert-AtlasInstallOptionSet -Options @($kept.Options) -Groups $groups
    }

    $null = Start-AtlasInstallState -TargetVersion $targetVersion -Mode $mode -Choices $updatePath.Choices `
        -CaptureNonce ([guid]::NewGuid().ToString('D'))
    Set-AtlasInstallOptions -Options $options | Out-Null
    return "Atlas install state ready for $mode of $targetVersion with options: $($options -join ', ')."
}

try {
    # The native TrustedInstaller child has no inherited console or standard handles.
    # Persist failures before bootstrap/module loading, then let the broker relay them.
    [void][IO.Directory]::CreateDirectory([IO.Path]::GetDirectoryName($sessionLog))
    [IO.File]::WriteAllText($sessionLog, '', [Text.UTF8Encoding]::new($false))
    Write-AtlasSessionLog "Starting install phase $Phase."
    if (-not [IO.File]::Exists($bootstrap)) {
        throw "The PowerShell bootstrap is missing at '$bootstrap'."
    }
    . $bootstrap
    Import-Module -Name (Join-Path -Path $scriptsRoot -ChildPath 'Modules\Atlas.Core\Atlas.Core.psd1') -Force -ErrorAction Stop
    Import-Module -Name (Join-Path -Path $scriptsRoot -ChildPath 'Modules\Atlas.InstallState\Atlas.InstallState.psd1') -Force -DisableNameChecking -ErrorAction Stop
    Assert-AtlasPrivilege -TrustedInstaller

    $payloadRoot = [IO.Path]::GetFullPath([IO.Path]::Combine($scriptsRoot, '..', '..'))
    $playbookPath = [IO.Path]::Combine($payloadRoot, '..', 'playbook.conf')

    switch ($Phase) {
        'Capture' {
            $message = Invoke-AtlasInstallCapture -PlaybookPath $playbookPath -PayloadRoot $payloadRoot
            Write-AtlasSessionLog $message
            Write-Output $message
        }
        'Run' {
            # Before this run appends to the shared logs, so one moved aside ends
            # with a whole line.
            try { Invoke-AtlasInstallLogRetention }
            catch { Write-AtlasSessionLog "WARNING: The install logs couldn't be tidied: $($_.Exception.Message)" }
            $captureScript = Join-Path -Path $scriptsRoot -ChildPath 'Entry\Initialize-AtlasInstallState.ps1'
            & $captureScript -Operation Commit
            $installScript = Join-Path -Path $scriptsRoot -ChildPath 'Entry\Invoke-AtlasInstall.ps1'
            & $installScript -Run *>&1 | ForEach-Object {
                Write-AtlasSessionLog ([string]$_)
                Write-Output $_
            }
            $planExitCode = $LASTEXITCODE
            Write-AtlasSessionLog "Install plan exited with code $planExitCode."
            Save-AtlasSessionLog
            exit $planExitCode
        }
    }
    Save-AtlasSessionLog
    exit 0
}
catch {
    $failure = $_
    $exitCode = if ($failure.Exception.Message -like '[[]privilege[]]*') { 2 } else { 1 }
    try {
        Write-AtlasSessionLog "ERROR: $($failure.Exception.ToString())`r`n$($failure.InvocationInfo.PositionMessage)`r`n$($failure.ScriptStackTrace)"
    }
    catch { [Console]::Error.WriteLine("Could not persist install failure: $($_.Exception.Message)") }
    [Console]::Error.WriteLine($failure.Exception.Message)
    Save-AtlasSessionLog
    exit $exitCode
}
