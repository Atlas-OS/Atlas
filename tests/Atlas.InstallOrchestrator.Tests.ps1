Describe 'Atlas install orchestrator' {
    BeforeAll {
        $repoRoot = Split-Path -Parent $PSScriptRoot
        $scriptPath = Join-Path -Path $repoRoot `
            -ChildPath 'playbook\Executables\AtlasModules\Scripts\Invoke-AtlasInstall.ps1'
        . $scriptPath
    }

    It 'maps lifecycle checkpoints to fixed scripts and typed arguments' {
        $source = Join-Path $TestDrive 'source\Scripts'
        $installed = Join-Path $TestDrive 'installed\Scripts'

        $disable = Get-AtlasInstallCheckpointAction -Target NotificationDisable `
            -ScriptsRoot $installed -SourceScriptsRoot $source
        $disable.Path | Should -Be ([IO.Path]::Combine(
                [IO.Path]::GetFullPath($installed),
                'Internal\Set-NotificationState.ps1'
            ))
        $disable.Arguments.Mode | Should -BeExactly 'Disable'

        $restore = Get-AtlasInstallCheckpointAction -Target NotificationRestore `
            -ScriptsRoot $installed -SourceScriptsRoot $source
        $restore.Arguments.Mode | Should -BeExactly 'Enable'

        $load = Get-AtlasInstallCheckpointAction -Target DefaultHiveLoad `
            -ScriptsRoot $source -SourceScriptsRoot $source
        $load.Arguments.State | Should -BeExactly 'Loaded'

        $unload = Get-AtlasInstallCheckpointAction -Target DefaultHiveUnload `
            -ScriptsRoot $installed -SourceScriptsRoot $source
        $unload.Arguments.State | Should -BeExactly 'Unloaded'
    }

    It 'always runs payload replacement from the extracted scripts root' {
        $source = Join-Path $TestDrive 'source\Scripts'
        $installed = Join-Path $TestDrive 'installed\Scripts'
        $action = Get-AtlasInstallCheckpointAction -Target PayloadReplacement `
            -ScriptsRoot $installed -SourceScriptsRoot $source

        $action.Path | Should -Be ([IO.Path]::Combine(
                [IO.Path]::GetFullPath($source),
                'Tasks\Invoke-AtlasPayloadReplacement.ps1'
            ))
        $action.Arguments.Count | Should -Be 0
    }

    It 'switches to the installed payload only after replacement completes' {
        $source = Join-Path $TestDrive 'source\Scripts'
        $installed = Join-Path $TestDrive 'installed\Scripts'
        $calls = New-Object Collections.Generic.List[object]
        $steps = New-Object Collections.Generic.List[string]
        $plan = @(
            [pscustomobject]@{ Key = 'Environment'; Replay = 'Once' }
            [pscustomobject]@{ Key = 'Checkpoint/PayloadReplacement'; Replay = 'Always' }
            [pscustomobject]@{ Key = 'Features'; Replay = 'Once' }
        )
        $state = [pscustomobject]@{
            status = 'Running'; isOobe = $false; userSid = 'S-1-5-21-1-2-3-1001'
        }
        $stepInvoker = {
            param($Name, $Mode, $Action)
            $steps.Add("$Name|$Mode")
            & $Action
        }.GetNewClosure()
        $completeInvoker = {
            param($RequiredSteps)
            $script:completedForTest = @($RequiredSteps)
        }
        $runner = {
            param($Path, $Parameters)
            $calls.Add([pscustomobject]@{ Path = $Path; Parameters = $Parameters })
        }.GetNewClosure()

        try {
            Invoke-AtlasInstallPlanCore -State $state -Plan $plan `
                -SourceScriptsRoot $source -InstalledScriptsRoot $installed `
                -StepInvoker $stepInvoker -CompleteInvoker $completeInvoker `
                -ScriptRunner $runner -PhaseStarter {} `
                -PhaseStopper {}

            $calls[0].Path | Should -Be ([IO.Path]::Combine(
                    [IO.Path]::GetFullPath($source),
                    'Phases\Invoke-EnvironmentPhase.ps1'
                ))
            $calls[1].Path | Should -Be ([IO.Path]::Combine(
                    [IO.Path]::GetFullPath($source),
                    'Tasks\Invoke-AtlasPayloadReplacement.ps1'
                ))
            $calls[2].Path | Should -Be ([IO.Path]::Combine(
                    [IO.Path]::GetFullPath($installed),
                    'Phases\Invoke-FeaturesPhase.ps1'
                ))
            $steps.ToArray() | Should -Be @(
                'Environment|Once',
                'Checkpoint/PayloadReplacement|Always',
                'Features|Once'
            )
            $script:completedForTest | Should -Be @(
                'Environment',
                'Checkpoint/PayloadReplacement',
                'Features'
            )
        }
        finally {
            Remove-Variable -Scope Script -Name completedForTest -ErrorAction Ignore
        }
    }

    It 'unloads a default hive created by this invocation when a later step fails' {
        $calls = New-Object Collections.Generic.List[string]
        $state = [pscustomobject]@{
            status = 'Running'; isOobe = $false; userSid = 'S-1-5-21-1-2-3-1001'
        }
        $plan = @(
            [pscustomobject]@{ Key = 'Checkpoint/DefaultHiveLoad'; Replay = 'Always' }
            [pscustomobject]@{ Key = 'Environment'; Replay = 'Once' }
            [pscustomobject]@{ Key = 'Checkpoint/DefaultHiveUnload'; Replay = 'Always' }
        )
        $stepInvoker = {
            param($Name, $Mode, $Action)
            [void]$Name
            [void]$Mode
            & $Action
        }
        $runner = {
            param($Path, $Parameters)
            $calls.Add("$(Split-Path -Leaf $Path)|$($Parameters.Values -join ',')")
            if ((Split-Path -Leaf $Path) -eq 'Invoke-EnvironmentPhase.ps1') {
                throw 'phase failed'
            }
        }.GetNewClosure()

        {
            Invoke-AtlasInstallPlanCore -State $state -Plan $plan `
                -SourceScriptsRoot $TestDrive -InstalledScriptsRoot $TestDrive `
                -StepInvoker $stepInvoker -CompleteInvoker {} -ScriptRunner $runner `
                -PhaseStarter {} -PhaseStopper {}
        } | Should -Throw 'phase failed'

        $calls.ToArray() | Should -Be @(
            'Set-AtlasDefaultUserHive.ps1|Loaded',
            'Invoke-EnvironmentPhase.ps1|',
            'Set-NotificationState.ps1|Enable',
            'Set-AtlasDefaultUserHive.ps1|Unloaded'
        )
    }

    It 'does not unload a default hive when this invocation did not load it' {
        $calls = New-Object Collections.Generic.List[string]
        $state = [pscustomobject]@{
            status = 'Running'; isOobe = $false; userSid = 'S-1-5-21-1-2-3-1001'
        }
        $plan = @(
            [pscustomobject]@{ Key = 'Checkpoint/DefaultHiveLoad'; Replay = 'Always' }
        )
        $runner = {
            param($Path, $Parameters)
            $calls.Add("$(Split-Path -Leaf $Path)|$([string]$Parameters['State'])")
            throw 'load failed'
        }.GetNewClosure()

        {
            Invoke-AtlasInstallPlanCore -State $state -Plan $plan `
                -SourceScriptsRoot $TestDrive -InstalledScriptsRoot $TestDrive `
                -StepInvoker { param($Name, $Mode, $Action) [void]$Name; [void]$Mode; & $Action } `
                -CompleteInvoker {} -ScriptRunner $runner `
                -PhaseStarter {} -PhaseStopper {}
        } | Should -Throw 'load failed'

        $calls.ToArray() | Should -Be @(
            'Set-AtlasDefaultUserHive.ps1|Loaded',
            'Set-NotificationState.ps1|'
        )
    }

    It 'retries a planned default hive unload once as best-effort cleanup' {
        $calls = New-Object Collections.Generic.List[string]
        $unloadState = @{ Calls = 0 }
        $state = [pscustomobject]@{
            status = 'Running'; isOobe = $true; userSid = $null
        }
        $plan = @(
            [pscustomobject]@{ Key = 'Checkpoint/DefaultHiveLoad'; Replay = 'Always' }
            [pscustomobject]@{ Key = 'Checkpoint/DefaultHiveUnload'; Replay = 'Always' }
        )
        $runner = {
            param($Path, $Parameters)
            $stepState = [string]$Parameters['State']
            $calls.Add("$(Split-Path -Leaf $Path)|$stepState")
            if ($stepState -eq 'Unloaded') {
                $unloadState.Calls++
                if ($unloadState.Calls -eq 1) { throw 'first unload failed' }
            }
        }.GetNewClosure()

        {
            Invoke-AtlasInstallPlanCore -State $state -Plan $plan `
                -SourceScriptsRoot $TestDrive -InstalledScriptsRoot $TestDrive `
                -StepInvoker { param($Name, $Mode, $Action) [void]$Name; [void]$Mode; & $Action } `
                -CompleteInvoker {} -ScriptRunner $runner `
                -PhaseStarter {} -PhaseStopper {}
        } | Should -Throw 'first unload failed'

        $calls.ToArray() | Should -Be @(
            'Set-AtlasDefaultUserHive.ps1|Loaded',
            'Set-AtlasDefaultUserHive.ps1|Unloaded',
            'Set-NotificationState.ps1|',
            'Set-AtlasDefaultUserHive.ps1|Unloaded'
        )
    }

    It 'pairs phase lifecycle calls even when a phase script fails' {
        $events = New-Object Collections.Generic.List[string]
        $step = [pscustomobject]@{
            Key = 'Software'; Replay = 'Once'
        }
        $starter = {
            param($Phase)
            $events.Add("start:$Phase")
        }.GetNewClosure()
        $stopper = { $events.Add('stop') }.GetNewClosure()

        {
            Invoke-AtlasInstallAction -Step $step -ScriptsRoot $TestDrive `
                -SourceScriptsRoot $TestDrive `
                -ScriptRunner { throw 'phase failed' } `
                -PhaseStarter $starter -PhaseStopper $stopper
        } | Should -Throw 'phase failed'

        $events.ToArray() | Should -Be @('start:Software', 'stop')
    }

    It 'rejects an uncommitted state before invoking a step' {
        $state = [pscustomobject]@{
            status = 'Capturing'; isOobe = $true; userSid = $null
        }
        {
            Invoke-AtlasInstallPlanCore -State $state -Plan @() `
                -SourceScriptsRoot $TestDrive -InstalledScriptsRoot $TestDrive `
                -StepInvoker { throw 'step invoked unexpectedly' } `
                -CompleteInvoker {} -ScriptRunner {} `
                -PhaseStarter {} -PhaseStopper {}
        } | Should -Throw '*must be committed and Running*'
    }

    It 'requires the captured user for a non-OOBE install' {
        $state = [pscustomobject]@{
            status = 'Running'; isOobe = $false; userSid = $null
        }
        {
            Invoke-AtlasInstallPlanCore -State $state -Plan @() `
                -SourceScriptsRoot $TestDrive -InstalledScriptsRoot $TestDrive `
                -StepInvoker {} -CompleteInvoker {} -ScriptRunner {} `
                -PhaseStarter {} -PhaseStopper {}
        } | Should -Throw '*requires its captured user SID*'
    }

    It 'rejects plan-controlled script names outside the allowlists' {
        $step = [pscustomobject]@{
            Key = '..\payload'; Replay = 'Once'
        }
        {
            Invoke-AtlasInstallAction -Step $step -ScriptsRoot $TestDrive `
                -SourceScriptsRoot $TestDrive -ScriptRunner {} `
                -PhaseStarter {} -PhaseStopper {}
        } | Should -Throw '*Unsupported install phase*'
    }
}
