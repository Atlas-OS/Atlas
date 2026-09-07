BeforeAll {
    . (Join-Path $PSScriptRoot 'AtlasTestHost.ps1')
    Import-Module (Join-Path $script:AtlasTestModulesRoot 'Atlas.Core\Atlas.Core.psd1') -Force
    Import-Module (Join-Path $script:AtlasTestModulesRoot 'Atlas.Toggles\Atlas.Toggles.psd1') -Force
    Import-Module (Join-Path $script:AtlasTestModulesRoot 'Atlas.Search\Atlas.Search.psd1') -Force
    $script:indexRoot = Join-Path $script:AtlasTestRepoRoot 'playbook\Executables\AtlasModules\Toggles'
    . (Join-Path $script:indexRoot 'General\Indexing.ps1')
}
Describe 'Interactive indexing across the TrustedInstaller boundary' {
    BeforeEach {
        Mock Test-AtlasAdmin -ModuleName Atlas.Toggles { $true }
        Mock Test-AtlasSystem -ModuleName Atlas.Toggles { $false }
        Mock Test-AtlasTrustedInstaller -ModuleName Atlas.Toggles { $false }
        Mock Show-AtlasTogglePreamble -ModuleName Atlas.Toggles {}
        Mock Invoke-AtlasTogglePostAction -ModuleName Atlas.Toggles {}
        Mock Invoke-AtlasTrustedInstaller -ModuleName Atlas.Toggles {}
        Mock Read-AtlasYesNo -ModuleName Atlas.Toggles { $true }
    }
    It 'passes the yes choice as a fixed state to a silent broker' {
        Invoke-AtlasToggle -Name Indexing -State Enable -TogglesRoot $script:indexRoot
        Should -Invoke Invoke-AtlasTrustedInstaller -ModuleName Atlas.Toggles -Times 1 -Exactly -ParameterFilter {
            $Name -ceq 'Indexing' -and $State -ceq 'EnableRespectPowerModes' -and $Silent
        }
        Should -Invoke Read-AtlasYesNo -ModuleName Atlas.Toggles -Times 1 -Exactly
    }
    It 'passes the no choice without substituting the preserved value' {
        Mock Read-AtlasYesNo -ModuleName Atlas.Toggles { $false }
        Invoke-AtlasToggle -Name Indexing -State Enable -TogglesRoot $script:indexRoot
        Should -Invoke Invoke-AtlasTrustedInstaller -ModuleName Atlas.Toggles -Times 1 -Exactly -ParameterFilter {
            $State -ceq 'EnableIgnorePowerModes' -and $Silent
        }
    }
    It 'does not prompt or select an explicit power choice during silent replay' {
        Invoke-AtlasToggle -Name Indexing -State Enable -Silent -TogglesRoot $script:indexRoot
        Should -Not -Invoke Read-AtlasYesNo -ModuleName Atlas.Toggles
        Should -Invoke Invoke-AtlasTrustedInstaller -ModuleName Atlas.Toggles -Times 1 -Exactly -ParameterFilter { $State -ceq 'Enable' -and $Silent }
    }
    It 'keeps the administrator relaunch interactive' {
        Mock Test-AtlasAdmin -ModuleName Atlas.Toggles { $false }
        Mock Invoke-AtlasToggleElevatedChild -ModuleName Atlas.Toggles {}
        Invoke-AtlasToggle -Name Indexing -State Enable -TogglesRoot $script:indexRoot
        Should -Invoke Invoke-AtlasToggleElevatedChild -ModuleName Atlas.Toggles -Times 1 -Exactly -ParameterFilter { $ArgumentList -notcontains '-Silent' }
        Should -Not -Invoke Read-AtlasYesNo -ModuleName Atlas.Toggles
    }
    It 'rejects an unrecognized selector result before dispatch' {
        Mock Invoke-AtlasToggleFunction -ModuleName Atlas.Toggles { 'UnknownState' }
        { Invoke-AtlasToggle -Name Indexing -State Enable -TogglesRoot $script:indexRoot } | Should -Throw '*exactly one installed state name*'
        Should -Not -Invoke Invoke-AtlasTrustedInstaller -ModuleName Atlas.Toggles
    }
    It 'does not dispatch after a cancelled selector' {
        Mock Read-AtlasYesNo -ModuleName Atlas.Toggles { throw 'selection cancelled' }
        { Invoke-AtlasToggle -Name Indexing -State Enable -TogglesRoot $script:indexRoot } | Should -Throw '*selection cancelled*'
        Should -Not -Invoke Invoke-AtlasTrustedInstaller -ModuleName Atlas.Toggles
    }
}
Describe 'Selected indexing records reflect completed work' {
    BeforeEach {
        Mock Import-AtlasModule {}
        Mock Set-AtlasIndexingMachineState {}
        Mock Set-AtlasToggleState {}
    }
    It 'applies the explicit value and keeps the existing replay record' -ForEach @(
        @{ Choice = 'EnableRespectPowerModes'; Value = 1 }
        @{ Choice = 'EnableIgnorePowerModes'; Value = 0 }
    ) {
        Set-AtlasSelectedFullIndexing -Toggle @{ State = $Choice; StateRoot = 'HKCU:\Unused' }
        Should -Invoke Set-AtlasIndexingMachineState -Times 1 -Exactly -ParameterFilter { $State -ceq 'Full' -and $RespectPowerModes -eq $Value -and -not $PreservePowerModes }
        Should -Invoke Set-AtlasToggleState -Times 1 -Exactly -ParameterFilter { $Name -ceq 'Indexing' -and $State -eq 2 -and $StateRoot -ceq 'HKCU:\Unused' }
    }
    It 'does not overwrite a record if preset application fails' {
        Mock Set-AtlasIndexingMachineState { throw 'preset failed' }
        { Set-AtlasSelectedFullIndexing -Toggle @{ State = 'EnableRespectPowerModes'; StateRoot = 'HKCU:\Unused' } } | Should -Throw '*preset failed*'
        Should -Not -Invoke Set-AtlasToggleState
    }
}
