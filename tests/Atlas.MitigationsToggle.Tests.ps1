BeforeAll {
    . (Join-Path $PSScriptRoot 'AtlasTestHost.ps1')
    Import-Module (Join-Path $script:AtlasTestModulesRoot 'Atlas.Core\Atlas.Core.psd1') -Force
    Import-Module (Join-Path $script:AtlasTestModulesRoot 'Atlas.Toggles\Atlas.Toggles.psd1') -Force
    $script:togglesRoot = Join-Path $script:AtlasTestRepoRoot 'playbook\Executables\AtlasModules\Toggles'
}

# The machine work runs in the silent TrustedInstaller broker, so the warning before
# force-enabling every mitigation can only come from the administrator window.
Describe 'Enable All Mitigations confirmation' {
    BeforeEach {
        Mock Test-AtlasAdmin -ModuleName Atlas.Toggles { $true }
        Mock Test-AtlasSystem -ModuleName Atlas.Toggles { $false }
        Mock Test-AtlasTrustedInstaller -ModuleName Atlas.Toggles { $false }
        # The preamble itself runs: a definition-wide Warning would gate every state there.
        Mock Write-AtlasTitle -ModuleName Atlas.Toggles
        Mock Write-AtlasStep -ModuleName Atlas.Toggles
        Mock Invoke-AtlasTogglePostAction -ModuleName Atlas.Toggles
        Mock Write-AtlasWarning -ModuleName Atlas.Toggles
        $script:confirmed = $false
        $script:confirmedBeforeBroker = $null
        Mock Wait-AtlasContinue -ModuleName Atlas.Toggles { $script:confirmed = $true }
        Mock Invoke-AtlasTrustedInstaller -ModuleName Atlas.Toggles { $script:confirmedBeforeBroker = $script:confirmed }
    }

    It 'warns and waits in the administrator window before the broker runs' {
        Invoke-AtlasToggle -Name Mitigations -State Enable -TogglesRoot $script:togglesRoot

        Should -Invoke Write-AtlasWarning -ModuleName Atlas.Toggles -Times 1 -Exactly -ParameterFilter {
            ($Text -join ' ') -like '*force-enables every security mitigation*'
        }
        Should -Invoke Wait-AtlasContinue -ModuleName Atlas.Toggles -Times 1 -Exactly
        Should -Invoke Invoke-AtlasTrustedInstaller -ModuleName Atlas.Toggles -Times 1 -Exactly -ParameterFilter {
            $Name -ceq 'Mitigations' -and $State -ceq 'Enable' -and $Silent
        }
        $script:confirmedBeforeBroker | Should -BeTrue
    }

    It 'does not warn during silent replay' {
        Invoke-AtlasToggle -Name Mitigations -State Enable -Silent -TogglesRoot $script:togglesRoot

        Should -Not -Invoke Wait-AtlasContinue -ModuleName Atlas.Toggles
        Should -Invoke Invoke-AtlasTrustedInstaller -ModuleName Atlas.Toggles -Times 1 -Exactly -ParameterFilter {
            $State -ceq 'Enable' -and $Silent
        }
    }

    It 'leaves the other states without a confirmation' -ForEach @(
        @{ Choice = 'Disable' }
        @{ Choice = 'WindowsDefault' }
    ) {
        Invoke-AtlasToggle -Name Mitigations -State $Choice -TogglesRoot $script:togglesRoot

        Should -Not -Invoke Write-AtlasWarning -ModuleName Atlas.Toggles
        Should -Not -Invoke Wait-AtlasContinue -ModuleName Atlas.Toggles
        Should -Invoke Invoke-AtlasTrustedInstaller -ModuleName Atlas.Toggles -Times 1 -Exactly -ParameterFilter {
            $State -ceq $Choice
        }
    }
}
