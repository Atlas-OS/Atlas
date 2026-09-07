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
        DefaultHiveLoad = @{ Path = 'Install\Tasks\Set-AtlasDefaultUserHive.ps1'; Args = @{ State = 'Loaded' } }
        PayloadReplacement = @{ Path = 'Install\Tasks\Invoke-AtlasPayloadReplacement.ps1'; Args = @{} }
        LegacyChoices = @{ Path = 'Install\Tasks\Import-AtlasLegacyChoices.ps1'; Args = @{} }
        NotificationDisable = @{ Path = 'Install\Tasks\Set-NotificationState.ps1'; Args = @{ Mode = 'Disable' } }
        InitializePath = @{ Path = 'Install\Tasks\Initialize-AtlasPath.ps1'; Args = @{} }
        InstallingUserSetup = @{ Path = 'Install\Tasks\Invoke-AtlasInstallingUserSetup.ps1'; Args = @{} }
        OemBranding = @{ Path = 'Install\Tasks\Set-OemInformation.ps1'; Args = @{} }
        NotificationRestore = @{ Path = 'Install\Tasks\Set-NotificationState.ps1'; Args = @{ Mode = 'Enable' } }
        DefaultHiveUnload = @{ Path = 'Install\Tasks\Set-AtlasDefaultUserHive.ps1'; Args = @{ State = 'Unloaded' } }
    }
    $definition = $definitions[$Target]
    if ($null -eq $definition) {
        throw "Unsupported install checkpoint '$Target'."
    }
    # Replacement needs its source carrier.
    $root = if ($Target -ceq 'PayloadReplacement') {
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

function New-AtlasInstallPhaseCallbacks {
    # Tasks may import Atlas.Core from the installed payload or reload it. Keep
    # both lifecycle bodies bound to the same module instance so a reload
    # cannot orphan the transcript owned by an already-running phase. Invoking
    # FunctionInfo can resolve the replacement module with the same name in
    # Windows PowerShell 5.1; its ScriptBlock retains the original session state.
    $startCommand = Get-Command -Name Start-AtlasPhase -ErrorAction Ignore
    $stopCommand = Get-Command -Name Stop-AtlasPhase -ErrorAction Ignore
    $startBody = if ($null -ne $startCommand) { $startCommand.ScriptBlock } else { $null }
    $stopBody = if ($null -ne $stopCommand) { $stopCommand.ScriptBlock } else { $null }
    return [pscustomobject]@{
        Start = {
            param($Phase, $Category)
            if ($null -ne $startBody -and $null -ne $stopBody) {
                & $startBody -Phase $Phase -Category $Category
            }
        }.GetNewClosure()
        Stop = {
            param($Failed)
            if ($null -ne $startBody -and $null -ne $stopBody) {
                & $stopBody -Failed:([bool]$Failed)
            }
        }.GetNewClosure()
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
        'Services', 'Components', 'AppxSupport', 'Defaults'
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
            'Install',
            'Phases',
            'Invoke-TweaksPhase.ps1'
        )
        $arguments = @{ Category = $category }
    }
    elseif ($key.StartsWith('Tweak/', [StringComparison]::Ordinal)) {
        # One Standalone manifest tweak placed outside the category order.
        $target = $key.Substring('Tweak/'.Length)
        if ($target -cnotmatch '^[a-z0-9-]+(/[a-z0-9-]+)+$') {
            throw "Unsupported standalone tweak '$target'."
        }
        $phase = 'Tweaks'
        $category = $target
        $path = [IO.Path]::Combine(
            [IO.Path]::GetFullPath($ScriptsRoot),
            'Install',
            'Phases',
            'Invoke-TweaksPhase.ps1'
        )
        $arguments = @{ Slug = $target }
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
            'Install',
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
        [Parameter(Mandatory = $true)][scriptblock]$PhaseStopper,
        [scriptblock]$ProgressReporter = {}
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
    # Include the final state commit; completing the last action is not success yet.
    $totalWork = $Plan.Count + 1
    & $ProgressReporter 0 $totalWork

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
            & $ProgressReporter $requiredSteps.Count $totalWork

            if ($key -ceq 'Checkpoint/PayloadReplacement') {
                # A completed Once step also switches roots when resuming: its installed
                # payload is the durable postcondition of having completed that step.
                $scriptsRoot = $installedRoot
            }
        }

        $null = & $CompleteInvoker $requiredSteps.ToArray()
        $planCompleted = $true
        & $ProgressReporter $totalWork $totalWork
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

function New-AtlasInstallAnnouncedAction {
    param(
        [Parameter(Mandatory = $true)][string]$Name,
        [Parameter(Mandatory = $true)][scriptblock]$Action
    )

    # GetNewClosure creates a dynamic module, which cannot resolve this script's
    # private logging function by name when InstallState invokes the callback.
    $writeMessage = ${function:Write-AtlasInstallMessage}
    return {
        & $writeMessage -Message "Running install step '$Name'."
        & $Action
    }.GetNewClosure()
}

if (-not $Run) {
    return
}

try {
    $sourceScriptsRoot = [IO.Path]::GetFullPath([IO.Path]::GetDirectoryName($PSScriptRoot))
    $trustBootstrap = [IO.Path]::Combine(
        $sourceScriptsRoot,
        'Initialize-AtlasPowerShell.ps1'
    )
    if (-not [IO.File]::Exists($trustBootstrap)) {
        throw "The PowerShell trust bootstrap is missing at '$trustBootstrap'."
    }
    . $trustBootstrap

    $moduleRoot = [IO.Path]::Combine($sourceScriptsRoot, 'Modules')
    Import-Module -Name ([IO.Path]::Combine(
            $moduleRoot, 'Atlas.InstallState', 'Atlas.InstallState.psd1'
        )) -Force -DisableNameChecking -ErrorAction Stop
    Import-Module -Name ([IO.Path]::Combine(
            $moduleRoot, 'Atlas.Core', 'Atlas.Core.psd1'
        )) -Force -ErrorAction Stop
    . ([IO.Path]::Combine($sourceScriptsRoot, 'Install', 'Install-Plan.ps1'))

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
        $announcedAction = New-AtlasInstallAnnouncedAction -Name $Name -Action $Action
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
    $phaseCallbacks = New-AtlasInstallPhaseCallbacks

    Invoke-AtlasInstallPlanCore -State $state -Plan $plan `
        -SourceScriptsRoot $sourceScriptsRoot `
        -InstalledScriptsRoot $installedScriptsRoot `
        -StepInvoker $stepInvoker -CompleteInvoker $completeInvoker `
        -ScriptRunner $scriptRunner -PhaseStarter $phaseCallbacks.Start `
        -PhaseStopper $phaseCallbacks.Stop -ProgressReporter {
            param($Completed, $Total)
            Write-AtlasInstallMessage -Message "[AtlasProgress] $Completed/$Total"
        }
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
