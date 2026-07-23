<#
.SYNOPSIS
    Runs the committed Atlas install plan in one TrustedInstaller process.
.DESCRIPTION
    Without -Run this file only defines its small dispatch surface. That keeps the
    behavior testable without changing the host. custom.yml invokes it with -Run.

    Exit codes: 0 success, 1 install failure, 2 wrong privilege.
#>
[CmdletBinding()]
param([switch]$Run)

Set-StrictMode -Version 3.0
$ErrorActionPreference = 'Stop'

function Get-AtlasInstallCheckpointAction {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)][string]$Target,

        [Parameter(Mandatory = $true)][string]$ScriptsRoot,
        [Parameter(Mandatory = $true)][string]$SourceScriptsRoot
    )

    $definitions = @{
        DefaultHiveLoad = @{ Path = 'Internal\Set-AtlasDefaultUserHive.ps1'; Args = @{ State = 'Loaded' } }
        PayloadReplacement = @{ Path = 'Tasks\Invoke-AtlasPayloadReplacement.ps1'; Args = @{} }
        NotificationDisable = @{ Path = 'Internal\Set-NotificationState.ps1'; Args = @{ Mode = 'Disable' } }
        HiddenSettingsPages = @{
            Path = 'Invoke-AtlasInstallTweak.ps1'; Args = @{ Slug = 'qol/set-hidden-settings-pages' }
        }
        InitializePath = @{ Path = 'Tasks\Initialize-AtlasPath.ps1'; Args = @{} }
        DefaultRegistrySeed = @{ Path = 'Internal\Import-AtlasDefaultRegistry.ps1'; Args = @{} }
        PowerSettings = @{
            Path = 'Invoke-AtlasInstallTweak.ps1'; Args = @{ Slug = 'scripts/set-power-settings' }
        }
        InstallingUserSetup = @{ Path = 'Tasks\Invoke-AtlasInstallingUserSetup.ps1'; Args = @{} }
        OemBranding = @{ Path = 'Tasks\Set-OemInformation.ps1'; Args = @{} }
        NotificationRestore = @{ Path = 'Internal\Set-NotificationState.ps1'; Args = @{ Mode = 'Enable' } }
        DefaultHiveUnload = @{ Path = 'Internal\Set-AtlasDefaultUserHive.ps1'; Args = @{ State = 'Unloaded' } }
    }
    $definition = $definitions[$Target]
    if ($null -eq $definition) {
        throw "Unsupported install checkpoint '$Target'."
    }
    # Replacement needs its source carrier; DEFAULT.reg sits beside that carrier.
    $root = if (@('PayloadReplacement', 'DefaultRegistrySeed') -ccontains $Target) {
        $SourceScriptsRoot
    }
    else { $ScriptsRoot }

    return [pscustomobject][ordered]@{
        Path = [IO.Path]::Combine(
            [IO.Path]::GetFullPath($root),
            [string]$definition.Path
        )
        Arguments = [hashtable]$definition.Args
    }
}

function Invoke-AtlasInstallAction {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)][object]$Step,
        [Parameter(Mandatory = $true)][string]$ScriptsRoot,
        [Parameter(Mandatory = $true)][string]$SourceScriptsRoot,
        [Parameter(Mandatory = $true)][scriptblock]$ScriptRunner,
        [Parameter(Mandatory = $true)][scriptblock]$PhaseStarter,
        [Parameter(Mandatory = $true)][scriptblock]$PhaseStopper
    )

    $phaseTargets = @(
        'PreInstall', 'ShellRefresh', 'Environment', 'Features', 'Software',
        'Services', 'Components', 'AppxSupport', 'Defaults', 'Revert'
    )
    $tweakTargets = @(
        'networking', 'performance', 'privacy', 'qol',
        'security', 'debloat', 'scripts', 'misc'
    )

    $key = [string]$Step.Key
    if ([string]::IsNullOrWhiteSpace($key)) {
        throw 'Install plan step has no key.'
    }

    if ($key.StartsWith('Checkpoint/', [StringComparison]::Ordinal)) {
        $target = $key.Substring('Checkpoint/'.Length)
        $action = Get-AtlasInstallCheckpointAction -Target $target `
            -ScriptsRoot $ScriptsRoot -SourceScriptsRoot $SourceScriptsRoot
        & $ScriptRunner $action.Path $action.Arguments
        return
    }

    if ($key.StartsWith('Tweaks/', [StringComparison]::Ordinal)) {
        $target = $key.Substring('Tweaks/'.Length)
        if ($tweakTargets -cnotcontains $target) {
            throw "Unsupported tweak category '$target'."
        }
        $phase = 'Tweaks'
        $category = $target
        $path = [IO.Path]::Combine(
            [IO.Path]::GetFullPath($ScriptsRoot),
            'Phases',
            'Invoke-TweaksPhase.ps1'
        )
        $arguments = @{ Category = $category }
    }
    else {
        $target = $key
        if ($phaseTargets -cnotcontains $target) {
            throw "Unsupported install phase '$target'."
        }
        $phase = $target
        $category = $null
        $path = [IO.Path]::Combine(
            [IO.Path]::GetFullPath($ScriptsRoot),
            'Phases',
            "Invoke-${target}Phase.ps1"
        )
        $arguments = @{}
    }

    $phaseFailed = $true
    try {
        & $PhaseStarter $phase $category
        & $ScriptRunner $path $arguments
        $phaseFailed = $false
    }
    finally {
        & $PhaseStopper $phaseFailed
    }
}

function Invoke-AtlasInstallPlanCore {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)][object]$State,
        [Parameter(Mandatory = $true)][AllowEmptyCollection()][object[]]$Plan,
        [Parameter(Mandatory = $true)][string]$SourceScriptsRoot,
        [Parameter(Mandatory = $true)][string]$InstalledScriptsRoot,
        [Parameter(Mandatory = $true)][scriptblock]$StepInvoker,
        [Parameter(Mandatory = $true)][scriptblock]$CompleteInvoker,
        [Parameter(Mandatory = $true)][scriptblock]$ScriptRunner,
        [Parameter(Mandatory = $true)][scriptblock]$PhaseStarter,
        [Parameter(Mandatory = $true)][scriptblock]$PhaseStopper
    )

    if ([string]$State.status -cne 'Running') {
        throw "Atlas install state must be committed and Running, not '$($State.status)'."
    }
    if (-not [bool]$State.isOobe -and
        [string]::IsNullOrWhiteSpace([string]$State.userSid)) {
        throw 'A non-OOBE Atlas install requires its captured user SID.'
    }

    $scriptsRoot = [IO.Path]::GetFullPath($SourceScriptsRoot)
    $installedRoot = [IO.Path]::GetFullPath($InstalledScriptsRoot)
    $requiredSteps = New-Object Collections.Generic.List[string]
    $actionInvoker = ${function:Invoke-AtlasInstallAction}
    $runner = $ScriptRunner
    $startPhase = $PhaseStarter
    $stopPhase = $PhaseStopper
    # A mutable holder lets the action closure record that this invocation, rather
    # than a prior interrupted run, successfully created the fixed hive mount.
    $defaultHive = @{ MountedByThisInvocation = $false }
    $planCompleted = $false

    try {
        foreach ($step in $Plan) {
            $key = [string]$step.Key
            $replay = [string]$step.Replay
            $action = {
                & $actionInvoker -Step $step -ScriptsRoot $scriptsRoot `
                    -SourceScriptsRoot $SourceScriptsRoot `
                    -ScriptRunner $runner -PhaseStarter $startPhase `
                    -PhaseStopper $stopPhase

                if ($key -ceq 'Checkpoint/DefaultHiveLoad') {
                    $defaultHive.MountedByThisInvocation = $true
                }
                elseif ($key -ceq 'Checkpoint/DefaultHiveUnload') {
                    $defaultHive.MountedByThisInvocation = $false
                }
            }.GetNewClosure()

            $null = & $StepInvoker $key $replay $action
            $requiredSteps.Add($key)

            if ($key -ceq 'Checkpoint/PayloadReplacement') {
                # A completed Once step also switches roots when resuming: its installed
                # payload is the durable postcondition of having completed that step.
                $scriptsRoot = $installedRoot
            }
        }

        $null = & $CompleteInvoker $requiredSteps.ToArray()
        $planCompleted = $true
    }
    finally {
        if (-not $planCompleted) {
            # Best-effort: the restore checkpoint no-ops without a recorded snapshot,
            # and the install failure already in flight stays authoritative.
            try {
                $restoreStep = [pscustomobject]@{
                    Key = 'Checkpoint/NotificationRestore'; Replay = 'Always'
                }
                $null = & $actionInvoker -Step $restoreStep -ScriptsRoot $scriptsRoot `
                    -SourceScriptsRoot $SourceScriptsRoot `
                    -ScriptRunner $runner -PhaseStarter $startPhase `
                    -PhaseStopper $stopPhase
            }
            catch {
                Write-Warning `
                    "Failed to restore the notification policy during install cleanup: $($_.Exception.Message)" `
                    -WarningAction Continue
            }
        }
        if ([bool]$defaultHive.MountedByThisInvocation) {
            try {
                $cleanupStep = [pscustomobject]@{
                    Key = 'Checkpoint/DefaultHiveUnload'; Replay = 'Always'
                }
                $null = & $actionInvoker -Step $cleanupStep -ScriptsRoot $scriptsRoot `
                    -SourceScriptsRoot $SourceScriptsRoot `
                    -ScriptRunner $runner -PhaseStarter $startPhase `
                    -PhaseStopper $stopPhase
                $defaultHive.MountedByThisInvocation = $false
            }
            catch {
                # Preserve the install failure already in flight. The next run's
                # Always load checkpoint will reconcile the fixed Atlas mount again.
                Write-Warning `
                    "Failed to unload the Atlas default-user hive during install cleanup: $($_.Exception.Message)" `
                    -WarningAction Continue
            }
        }
    }
}

function Write-AtlasInstallMessage {
    param(
        [Parameter(Mandatory = $true)][string]$Message,
        [ValidateSet('Info', 'Warning', 'Error')][string]$Level = 'Info',
        [Management.Automation.ErrorRecord]$ErrorRecord
    )

    try {
        if ($null -ne (Get-Command -Name Write-AtlasLog -ErrorAction Ignore)) {
            Write-AtlasLog -Message $Message -Level $Level -ErrorRecord $ErrorRecord
            return
        }
    }
    catch {
        $null = $_
    }
    if ($Level -eq 'Error') { Write-Error $Message -ErrorAction Continue }
    elseif ($Level -eq 'Warning') { Write-Warning $Message }
    else { Write-Output $Message }
}

if (-not $Run) {
    return
}

try {
    $sourceScriptsRoot = [IO.Path]::GetFullPath($PSScriptRoot)
    $trustBootstrap = [IO.Path]::Combine(
        $sourceScriptsRoot,
        'Internal',
        'Initialize-PowerShellTrust.ps1'
    )
    if (-not [IO.File]::Exists($trustBootstrap)) {
        throw "The PowerShell trust bootstrap is missing at '$trustBootstrap'."
    }
    . $trustBootstrap

    $atlasModulesRoot = [IO.Directory]::GetParent($sourceScriptsRoot).FullName
    & ([IO.Path]::Combine($atlasModulesRoot, 'initPowerShell.ps1'))

    $moduleRoot = [IO.Path]::Combine($sourceScriptsRoot, 'Modules')
    Import-Module -Name ([IO.Path]::Combine(
            $moduleRoot, 'Atlas.InstallState', 'Atlas.InstallState.psd1'
        )) -Force -DisableNameChecking -ErrorAction Stop
    Import-Module -Name ([IO.Path]::Combine(
            $moduleRoot, 'Atlas.Core', 'Atlas.Core.psd1'
        )) -Force -ErrorAction Stop
    . ([IO.Path]::Combine($sourceScriptsRoot, 'Internal', 'Install-Plan.ps1'))

    Assert-AtlasPrivilege -TrustedInstaller
    $state = Get-AtlasInstallState
    if ($null -eq $state) {
        throw 'No committed Atlas install state is active.'
    }
    $plan = @(Get-AtlasInstallPlan -Mode ([string]$state.mode) `
            -IsOobe ([bool]$state.isOobe))
    $installedScriptsRoot = [IO.Path]::Combine(
        [Environment]::GetFolderPath('Windows'),
        'AtlasModules',
        'Scripts'
    )
    $installFlagsPath = [IO.Path]::Combine(
        [IO.Directory]::GetParent($installedScriptsRoot).FullName,
        'Flags'
    )

    $stepInvoker = {
        param($Name, $Mode, $Action)
        # The running announcement lives inside the action so a skipped step logs
        # only its skip decision.
        $announcedAction = {
            Write-AtlasInstallMessage -Message "Running install step '$Name'."
            & $Action
        }.GetNewClosure()
        $step = Invoke-AtlasInstallStep -Name $Name -Mode $Mode -Action $announcedAction
        if ($step.Skipped) {
            Write-AtlasInstallMessage -Message "Skipped already-completed install step '$Name'."
        }
        else {
            Write-AtlasInstallMessage -Message "Finished install step '$Name'."
        }
        return $step
    }
    $completeInvoker = {
        param($RequiredSteps)
        Complete-AtlasInstallState -RequiredSteps $RequiredSteps `
            -FlagsPath $installFlagsPath
    }.GetNewClosure()
    $scriptRunner = {
        param($Path, $Parameters)
        if (-not [IO.File]::Exists($Path)) {
            throw "Install action is missing at '$Path'."
        }
        & $Path @Parameters
    }
    $phaseStarter = {
        param($Phase, $Category)
        if ($null -ne (Get-Command -Name Start-AtlasPhase -ErrorAction Ignore)) {
            Start-AtlasPhase -Phase $Phase -Category $Category
        }
    }
    $phaseStopper = {
        param($Failed)
        if ($null -ne (Get-Command -Name Stop-AtlasPhase -ErrorAction Ignore)) {
            Stop-AtlasPhase -Failed:([bool]$Failed)
        }
    }

    Invoke-AtlasInstallPlanCore -State $state -Plan $plan `
        -SourceScriptsRoot $sourceScriptsRoot `
        -InstalledScriptsRoot $installedScriptsRoot `
        -StepInvoker $stepInvoker -CompleteInvoker $completeInvoker `
        -ScriptRunner $scriptRunner -PhaseStarter $phaseStarter `
        -PhaseStopper $phaseStopper
    Write-AtlasInstallMessage -Message 'Atlas installation completed successfully.'
    exit 0
}
catch {
    $failure = $_
    $exitCode = if ($failure.Exception.Message -like '[[]privilege[]]*') { 2 } else { 1 }

    Write-AtlasInstallMessage -Level Error -Message $failure.Exception.Message `
        -ErrorRecord $failure
    exit $exitCode
}
