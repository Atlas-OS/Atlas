Describe 'Atlas install orchestrator' {
    BeforeAll {
        . (Join-Path $PSScriptRoot 'AtlasTestHost.ps1')
        . (Join-Path $script:AtlasTestScriptsRoot 'Entry\Invoke-AtlasInstall.ps1')
        . (Join-Path $script:AtlasTestScriptsRoot 'Install\Install-Plan.ps1')
    }

    It 'reports completed work and reserves full progress for a successful commit' -TestCases @(
        @{ Failure = 'None'; Expected = @('0/3', '1/3', '2/3', '3/3') }
        @{ Failure = 'Step'; Expected = @('0/3') }
        @{ Failure = 'Commit'; Expected = @('0/3', '1/3', '2/3') }
    ) {
        param($Failure, $Expected)
        $progress = New-Object 'Collections.Generic.List[string]'
        $reporter = { param($Completed, $Total) $progress.Add("$Completed/$Total") }.GetNewClosure()
        $stepInvoker = {
            if ($Failure -eq 'Step') { throw 'step failed' }
            # Resumed steps count as completed without replaying their actions.
            [pscustomobject]@{ Skipped = $true }
        }.GetNewClosure()
        $commit = { if ($Failure -eq 'Commit') { throw 'commit failed' } }.GetNewClosure()
        $parameters = @{
            State = [pscustomobject]@{ status = 'Running'; isOobe = $true }
            Plan = @(
                [pscustomobject]@{ Key = 'Environment'; Replay = 'Once' }
                [pscustomobject]@{ Key = 'Features'; Replay = 'Once' }
            )
            SourceScriptsRoot = (Join-Path $TestDrive 'source')
            InstalledScriptsRoot = (Join-Path $TestDrive 'installed')
            StepInvoker = $stepInvoker; CompleteInvoker = $commit
            ScriptRunner = {}; PhaseStarter = {}; PhaseStopper = {}
            ProgressReporter = $reporter
        }
        if ($Failure -eq 'None') {
            Invoke-AtlasInstallPlanCore @parameters
        } else {
            { Invoke-AtlasInstallPlanCore @parameters } | Should -Throw '*failed*'
        }
        $progress.ToArray() | Should -Be $Expected
    }

    It 'announces and runs an action through the install-state module' {
        $probe = New-Module -ScriptBlock {
            function Invoke-Probe { param([scriptblock]$Action) & $Action }
            Export-ModuleMember -Function Invoke-Probe
        }
        $action = New-AtlasInstallAnnouncedAction -Name 'PreInstall' -Action { 'action ran' }
        $output = & $probe { param($Callback) Invoke-Probe -Action $Callback } $action
        $output | Should -BeExactly 'action ran'
    }

    It 'keeps the owning phase module across a same-name on-disk module import' {
        # Tasks can re-import Atlas.Core from the installed copy; the running phase
        # must still be closed by the module instance that opened it.
        $probeRoot = Join-Path $TestDrive ([guid]::NewGuid().ToString('N'))
        $eventsPath = Join-Path $probeRoot 'events.txt'
        $body = @'
$script:active = $false
function Start-AtlasPhase {
    param($Phase, $Category)
    $script:active = $true
    Add-Content -LiteralPath '__EVENTS__' -Value "start:$Phase/$Category"
}
function Stop-AtlasPhase {
    param([switch]$Failed)
    if ($script:active) {
        Add-Content -LiteralPath '__EVENTS__' -Value "stop:$Failed"
        $script:active = $false
    }
}
Export-ModuleMember -Function Start-AtlasPhase,Stop-AtlasPhase
'@
        foreach ($location in @('source', 'installed')) {
            $directory = Join-Path $probeRoot $location
            $null = New-Item -ItemType Directory -Path $directory -Force
            Set-Content -LiteralPath (Join-Path $directory 'AtlasPhaseDiskProbe.psm1') `
                -Value $body.Replace('__EVENTS__', $eventsPath.Replace("'", "''"))
        }
        $owner = Import-Module (Join-Path $probeRoot 'source\AtlasPhaseDiskProbe.psm1') -Force -PassThru
        try {
            Mock Get-Command { $owner.ExportedCommands[$Name] } -ParameterFilter {
                $Name -in @('Start-AtlasPhase', 'Stop-AtlasPhase')
            }
            $callbacks = New-AtlasInstallPhaseCallbacks
            & $callbacks.Start 'PreInstall' 'probe'
            & { Import-Module (Join-Path $probeRoot 'installed\AtlasPhaseDiskProbe.psm1') -Force }
            & $callbacks.Stop $true
            & $callbacks.Start 'Next' $null
            & $callbacks.Stop $false
            @(Get-Content -LiteralPath $eventsPath) | Should -Be @(
                'start:PreInstall/probe', 'stop:True', 'start:Next/', 'stop:False'
            )
        }
        finally {
            Remove-Module -Name AtlasPhaseDiskProbe -Force -ErrorAction SilentlyContinue
        }
    }

    It 'maps every planned checkpoint to a task script that accepts its arguments' {
        $keys = foreach ($mode in 'Fresh', 'Upgrade', 'Reapply', 'Rebase') {
            foreach ($isOobe in $false, $true) { (Get-AtlasInstallPlan -Mode $mode -IsOobe $isOobe).Key }
        }
        $targets = @($keys | Where-Object { $_.StartsWith('Checkpoint/', [StringComparison]::Ordinal) } |
                ForEach-Object { $_.Substring('Checkpoint/'.Length) } | Sort-Object -Unique)
        $targets.Count | Should -BeGreaterThan 0

        foreach ($target in $targets) {
            $action = Get-AtlasInstallCheckpointAction -Target $target `
                -ScriptsRoot $script:AtlasTestScriptsRoot -SourceScriptsRoot $script:AtlasTestScriptsRoot
            $action.Path | Should -Exist -Because $target
            $parameters = (Get-Command -Name $action.Path).Parameters
            foreach ($name in $action.Arguments.Keys) {
                $value = $action.Arguments[$name]
                $parameters.Keys | Should -Contain $name -Because "$target passes -$name"
                foreach ($set in @($parameters[$name].Attributes | Where-Object { $_ -is [ValidateSet] })) {
                    $value | Should -BeIn $set.ValidValues -Because "$target passes -$name $value"
                }
            }
        }

        # Resumes can start from the installed root; replacement must still run the
        # extracted files, not the stale installed copy. Every other checkpoint runs
        # from the root it is given.
        $source = Join-Path $TestDrive 'source\Scripts'
        $installed = Join-Path $TestDrive 'installed\Scripts'
        (Get-AtlasInstallCheckpointAction -Target PayloadReplacement -ScriptsRoot $installed -SourceScriptsRoot $source).Path |
            Should -Be ([IO.Path]::Combine([IO.Path]::GetFullPath($source), 'Install\Tasks\Invoke-AtlasPayloadReplacement.ps1'))
        $installedRoot = [WildcardPattern]::Escape([IO.Path]::GetFullPath($installed))
        foreach ($target in @($targets | Where-Object { $_ -cne 'PayloadReplacement' })) {
            (Get-AtlasInstallCheckpointAction -Target $target -ScriptsRoot $installed -SourceScriptsRoot $source).Path |
                Should -BeLike "$installedRoot\*" -Because $target
        }
    }

    It 'runs every planned phase step from an existing phase script and plans every phase script' {
        $steps = foreach ($mode in 'Fresh', 'Upgrade', 'Reapply', 'Rebase') {
            foreach ($isOobe in $false, $true) {
                Get-AtlasInstallPlan -Mode $mode -IsOobe $isOobe |
                    Where-Object { -not $_.Key.StartsWith('Checkpoint/', [StringComparison]::Ordinal) }
            }
        }
        $ran = New-Object 'Collections.Generic.List[string]'
        $runner = { param($Path) $ran.Add($Path) }.GetNewClosure()
        foreach ($step in $steps) {
            Invoke-AtlasInstallAction -Step $step -ScriptsRoot $script:AtlasTestScriptsRoot `
                -SourceScriptsRoot $script:AtlasTestScriptsRoot -ScriptRunner $runner `
                -PhaseStarter {} -PhaseStopper {}
        }

        $planned = @($ran | Sort-Object -Unique)
        foreach ($path in $planned) {
            $path | Should -Exist
        }
        $onDisk = @(Get-ChildItem -LiteralPath (Join-Path $script:AtlasTestScriptsRoot 'Install\Phases') `
                -Filter 'Invoke-*Phase.ps1' -File | ForEach-Object FullName)
        foreach ($path in $onDisk) {
            $planned | Should -Contain $path -Because 'a phase script no plan reaches never runs'
        }
    }

    It 'switches to the installed files only after replacement completes' {
        $source = Join-Path $TestDrive 'source\Scripts'
        $installed = Join-Path $TestDrive 'installed\Scripts'
        $calls = New-Object Collections.Generic.List[object]
        $steps = New-Object Collections.Generic.List[string]
        $completed = New-Object Collections.Generic.List[string]
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
            $completed.AddRange([string[]]@($RequiredSteps))
        }.GetNewClosure()
        $runner = {
            param($Path, $Parameters)
            $calls.Add([pscustomobject]@{ Path = $Path; Parameters = $Parameters })
        }.GetNewClosure()

        Invoke-AtlasInstallPlanCore -State $state -Plan $plan `
            -SourceScriptsRoot $source -InstalledScriptsRoot $installed `
            -StepInvoker $stepInvoker -CompleteInvoker $completeInvoker `
            -ScriptRunner $runner -PhaseStarter {} `
            -PhaseStopper {}

        $calls[0].Path | Should -Be ([IO.Path]::Combine(
                [IO.Path]::GetFullPath($source),
                'Install\Phases\Invoke-EnvironmentPhase.ps1'
            ))
        $calls[1].Path | Should -Be ([IO.Path]::Combine(
                [IO.Path]::GetFullPath($source),
                'Install\Tasks\Invoke-AtlasPayloadReplacement.ps1'
            ))
        $calls[2].Path | Should -Be ([IO.Path]::Combine(
                [IO.Path]::GetFullPath($installed),
                'Install\Phases\Invoke-FeaturesPhase.ps1'
            ))
        $steps.ToArray() | Should -Be @(
            'Environment|Once',
            'Checkpoint/PayloadReplacement|Always',
            'Features|Once'
        )
        $completed.ToArray() | Should -Be @(
            'Environment',
            'Checkpoint/PayloadReplacement',
            'Features'
        )
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

    It 'rejects plan-controlled script names outside the allowlists: <Key>' -TestCases @(
        @{ Key = '..\payload'; Message = '*Unsupported install phase*' }
        @{ Key = 'Checkpoint/Unknown'; Message = "*Unsupported install checkpoint 'Unknown'*" }
    ) {
        $step = [pscustomobject]@{ Key = $Key; Replay = 'Once' }
        {
            Invoke-AtlasInstallAction -Step $step -ScriptsRoot $TestDrive `
                -SourceScriptsRoot $TestDrive -ScriptRunner { throw 'runner must not be invoked' } `
                -PhaseStarter {} -PhaseStopper {}
        } | Should -Throw $Message
    }

    It 'dispatches a standalone tweak step to the Tweaks phase with its slug' {
        $installed = Join-Path $TestDrive 'installed\Scripts'
        $calls = New-Object Collections.Generic.List[object]
        $events = New-Object Collections.Generic.List[string]
        $step = [pscustomobject]@{ Key = 'Tweak/qol/set-hidden-settings-pages'; Replay = 'Once' }
        $runner = {
            param($Path, $Parameters)
            $calls.Add([pscustomobject]@{ Path = $Path; Parameters = $Parameters })
        }.GetNewClosure()
        $starter = {
            param($Phase, $Category)
            $events.Add("start:$Phase|$Category")
        }.GetNewClosure()
        $stopper = {
            param($Failed)
            $events.Add("stop:$Failed")
        }.GetNewClosure()

        Invoke-AtlasInstallAction -Step $step -ScriptsRoot $installed `
            -SourceScriptsRoot (Join-Path $TestDrive 'source\Scripts') `
            -ScriptRunner $runner -PhaseStarter $starter -PhaseStopper $stopper

        $calls.Count | Should -Be 1
        $calls[0].Path | Should -Be ([IO.Path]::Combine(
                [IO.Path]::GetFullPath($installed),
                'Install\Phases\Invoke-TweaksPhase.ps1'
            ))
        @($calls[0].Parameters.Keys) | Should -Be @('Slug')
        $calls[0].Parameters.Slug | Should -BeExactly 'qol/set-hidden-settings-pages'
        $events.ToArray() | Should -Be @('start:Tweaks|qol/set-hidden-settings-pages', 'stop:False')
    }

    It 'rejects a malformed standalone tweak slug before running anything' -TestCases @(
        @{ Key = 'Tweak/Bad' }
        @{ Key = 'Tweak/qol/Set-Hidden' }
        @{ Key = 'Tweak/../qol/set-hidden-settings-pages' }
        @{ Key = 'Tweak/qol/set-hidden-settings-pages/' }
    ) {
        $step = [pscustomobject]@{ Key = $Key; Replay = 'Once' }
        {
            Invoke-AtlasInstallAction -Step $step -ScriptsRoot $TestDrive `
                -SourceScriptsRoot $TestDrive -ScriptRunner { throw 'runner must not be invoked' } `
                -PhaseStarter { throw 'phase must not start' } -PhaseStopper {}
        } | Should -Throw '*Unsupported standalone tweak*'
    }
}
