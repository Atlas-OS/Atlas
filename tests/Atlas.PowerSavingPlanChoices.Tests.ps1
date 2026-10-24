BeforeAll {
    . (Join-Path $PSScriptRoot 'AtlasTestHost.ps1')
    Import-Module (Join-Path $script:AtlasTestModulesRoot 'Atlas.Core\Atlas.Core.psd1') -Force
    Import-Module (Join-Path $script:AtlasTestModulesRoot 'Atlas.Hardware\Atlas.Hardware.psd1') -Force
    Import-Module (Join-Path $script:AtlasTestModulesRoot 'Atlas.Toggles\Atlas.Toggles.psd1') -Force

    $script:StateRoot = 'HKCU:\Software\AtlasRewriteTest\PowerSavingPlanChoices'
    $togglesRoot = Join-Path $script:AtlasTestRepoRoot 'playbook\Executables\AtlasModules\Toggles'
    $script:PowerSaving = Get-AtlasToggleDefinition -Name PowerSaving -TogglesRoot $togglesRoot
    $script:PlanDefinitions = @{}
    foreach ($name in @('CpuIdle', 'Sleep')) {
        $script:PlanDefinitions[$name] = Get-AtlasToggleDefinition -Name $name -TogglesRoot $togglesRoot
    }

    # Runs one PowerSaving state the way upgrade replay and Invoke-AtlasToggleMachineState
    # do, so the companion gets a real $Toggle and the engine records the state.
    function Invoke-PowerSavingState {
        param([Parameter(Mandatory = $true)][string]$State)

        InModuleScope Atlas.Toggles {
            Invoke-AtlasToggleInProcess -Definition $d -StateName $s -Scope Machine `
                -Silent -NoExplorerRestart -SkipPreamble -StateRoot $r
        } -Parameters @{ d = $script:PowerSaving; s = $State; r = $script:StateRoot }
    }
}

AfterAll {
    Remove-Item -Path 'HKCU:\Software\AtlasRewriteTest\PowerSavingPlanChoices' -Recurse -Force -ErrorAction SilentlyContinue
}

Describe 'PowerSaving carries the per-plan choices over to the new plan' {
    BeforeEach {
        Remove-Item -Path $script:StateRoot -Recurse -Force -ErrorAction SilentlyContinue
        $script:calls = New-Object 'Collections.Generic.List[string]'
        Mock Write-AtlasLog -ModuleName Atlas.Toggles
        Mock Import-AtlasModule -ModuleName Atlas.Toggles
        Mock Set-AtlasPowerSavingState -ModuleName Atlas.Toggles { $script:calls.Add("PowerSaving/$Mode") }
        Mock Invoke-AtlasToggleMachineState -ModuleName Atlas.Toggles { $script:calls.Add("$Name/$State") }
        # The companion reads the installed definitions, which a test host doesn't have.
        Mock Get-AtlasToggleDefinition -ModuleName Atlas.Toggles -ParameterFilter { $script:PlanDefinitions.Contains($Name) } {
            $script:PlanDefinitions[$Name]
        }
        # CpuIdle's real check reads the processor.
        Mock Test-AtlasToggleReplayApplicable -ModuleName Atlas.Toggles { $true }
    }

    It 'applies the recorded CpuIdle and Sleep choices after the plan change' {
        Set-AtlasToggleState -Name CpuIdle -State 0 -StateRoot $script:StateRoot
        Set-AtlasToggleState -Name Sleep -State 1 -StateRoot $script:StateRoot

        Invoke-PowerSavingState -State Disable

        @($script:calls) | Should -Be @('PowerSaving/Atlas', 'CpuIdle/Disable', 'Sleep/Enable')
        Should -Invoke Invoke-AtlasToggleMachineState -ModuleName Atlas.Toggles -Times 2 -Exactly -ParameterFilter {
            $StateRoot -ceq $script:StateRoot
        }
        (Get-AtlasToggleState -Name PowerSaving -StateRoot $script:StateRoot).State | Should -Be 0
    }

    It 'changes nothing else when no per-plan choice is recorded' {
        Invoke-PowerSavingState -State Enable

        @($script:calls) | Should -Be @('PowerSaving/Default')
        Should -Invoke Invoke-AtlasToggleMachineState -ModuleName Atlas.Toggles -Times 0 -Exactly
        (Get-AtlasToggleState -Name PowerSaving -StateRoot $script:StateRoot).State | Should -Be 1
    }

    It 'keeps its own result and warns when a recorded choice fails to apply' {
        Mock Invoke-AtlasToggleMachineState -ModuleName Atlas.Toggles {
            $script:calls.Add("$Name/$State")
            if ($Name -ceq 'CpuIdle') { throw 'powercfg exited with code 1.' }
        }
        Set-AtlasToggleState -Name CpuIdle -State 0 -StateRoot $script:StateRoot
        Set-AtlasToggleState -Name Sleep -State 0 -StateRoot $script:StateRoot

        { Invoke-PowerSavingState -State Enable } | Should -Not -Throw

        @($script:calls) | Should -Be @('PowerSaving/Default', 'CpuIdle/Disable', 'Sleep/Disable')
        Should -Invoke Write-AtlasLog -ModuleName Atlas.Toggles -Times 1 -Exactly -ParameterFilter {
            $Level -ceq 'Warning' -and $Message -like '*recorded CpuIdle choice*powercfg exited with code 1*'
        }
        (Get-AtlasToggleState -Name PowerSaving -StateRoot $script:StateRoot).State | Should -Be 1
    }

    It 'keeps its own result and warns when a recorded choice is not a DWORD' {
        Set-AtlasToggleState -Name Sleep -State 0 -StateRoot $script:StateRoot
        $cpuIdleKey = Join-Path $script:StateRoot 'CpuIdle'
        New-Item -Path $cpuIdleKey -Force | Out-Null
        New-ItemProperty -LiteralPath $cpuIdleKey -Name 'state' -PropertyType String -Value '0' -Force | Out-Null

        { Invoke-PowerSavingState -State Enable } | Should -Not -Throw

        @($script:calls) | Should -Be @('PowerSaving/Default', 'Sleep/Disable')
        Should -Invoke Write-AtlasLog -ModuleName Atlas.Toggles -Times 1 -Exactly -ParameterFilter {
            $Level -ceq 'Warning' -and $Message -like '*recorded CpuIdle choice*non-REG_DWORD*'
        }
        (Get-AtlasToggleState -Name PowerSaving -StateRoot $script:StateRoot).State | Should -Be 1
    }

    It 'leaves a recorded choice this PC cannot take, as upgrade replay does, without a warning' {
        # Disabling CPU idle with SMT on.
        Mock Test-AtlasToggleReplayApplicable -ModuleName Atlas.Toggles { $Definition['Name'] -cne 'CpuIdle' }
        Set-AtlasToggleState -Name CpuIdle -State 0 -StateRoot $script:StateRoot
        Set-AtlasToggleState -Name Sleep -State 1 -StateRoot $script:StateRoot

        Invoke-PowerSavingState -State Disable

        @($script:calls) | Should -Be @('PowerSaving/Atlas', 'Sleep/Enable')
        Should -Invoke Test-AtlasToggleReplayApplicable -ModuleName Atlas.Toggles -Times 1 -Exactly -ParameterFilter {
            $Definition['Name'] -ceq 'CpuIdle' -and $StateName -ceq 'Disable' -and $StateRoot -ceq $script:StateRoot
        }
        Should -Invoke Write-AtlasLog -ModuleName Atlas.Toggles -Times 0 -Exactly -ParameterFilter { $Level -ceq 'Warning' }
        (Get-AtlasToggleState -Name CpuIdle -StateRoot $script:StateRoot).State | Should -Be 0
    }
}
