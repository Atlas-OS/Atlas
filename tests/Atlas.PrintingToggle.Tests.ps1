BeforeAll {
    . (Join-Path $PSScriptRoot 'AtlasTestHost.ps1')
    Import-Module (Join-Path $script:AtlasTestModulesRoot 'Atlas.Core\Atlas.Core.psd1') -Force
    # The companion calls these after Import-AtlasModule (mocked below); load the real
    # modules once so the mocks have a command to shadow inside Atlas.Toggles.
    Import-Module (Join-Path $script:AtlasTestModulesRoot 'Atlas.Services\Atlas.Services.psd1') -Force
    Import-Module (Join-Path $script:AtlasTestModulesRoot 'Atlas.Shell\Atlas.Shell.psd1') -Force
    Import-Module (Join-Path $script:AtlasTestModulesRoot 'Atlas.Toggles\Atlas.Toggles.psd1') -Force
    $togglesRoot = Join-Path $script:AtlasTestRepoRoot 'playbook\Executables\AtlasModules\Toggles'
    $script:printing = Get-AtlasToggleDefinition -Name Printing -TogglesRoot $togglesRoot

    # Runs the machine action the way the engine does: with the engine's own $Toggle
    # context, dot-sourced inside Atlas.Toggles under strict mode.
    function Invoke-PrintingMachineAction {
        param([bool]$Silent = $true)

        InModuleScope Atlas.Toggles {
            $context = New-AtlasToggleContext -Definition $d -StateName 'Enable' -Silent:$silent -StateRoot 'HKCU:\Unused'
            Invoke-AtlasToggleFunction -Definition $d -FunctionName ([string]$d['States']['Enable']['MachineAction']) `
                -Toggle $context -Label 'test'
        } -Parameters @{ d = $script:printing; silent = $Silent }
    }
}

Describe 'Enable Printing with optional tools that cannot be added' {
    BeforeEach {
        Mock Write-AtlasLog -ModuleName Atlas.Toggles
        Mock Write-AtlasStep -ModuleName Atlas.Toggles
        Mock Write-AtlasPartial -ModuleName Atlas.Toggles
        Mock Import-AtlasModule -ModuleName Atlas.Toggles
        Mock Set-AtlasServiceStartup -ModuleName Atlas.Toggles
        Mock Set-AtlasSettingsPageVisibility -ModuleName Atlas.Toggles
        Mock Read-AtlasYesNo -ModuleName Atlas.Toggles { throw 'Silent work must not prompt.' }
        # Windows Update is off: every capability download fails, the features enable.
        Mock Invoke-AtlasToggleNativeCommand -ModuleName Atlas.Toggles {
            if ($ArgumentList -contains '/Add-Capability') {
                throw 'DISM exited with code 0x800f0954.'
            }
        }
    }

    It 'still enables printing during silent replay and logs the missing console' {
        Invoke-PrintingMachineAction

        Should -Invoke Invoke-AtlasToggleNativeCommand -ModuleName Atlas.Toggles -Times 4 -Exactly -ParameterFilter {
            $ArgumentList -contains '/Enable-Feature'
        }
        Should -Invoke Write-AtlasLog -ModuleName Atlas.Toggles -Times 1 -Exactly -ParameterFilter {
            $Level -eq 'Warning' -and $Message -like '*Print.Management.Console*0x800f0954*' -and -not $NoConsole
        }
        Should -Not -Invoke Write-AtlasPartial -ModuleName Atlas.Toggles
    }

    It 'reports each optional tool it could not add as partly done' {
        Mock Read-AtlasYesNo -ModuleName Atlas.Toggles { $true }

        Invoke-PrintingMachineAction -Silent $false

        Should -Invoke Write-AtlasPartial -ModuleName Atlas.Toggles -Times 1 -Exactly -ParameterFilter {
            ($Text -join ' ') -like '*the Print Management console*'
        }
        Should -Invoke Write-AtlasPartial -ModuleName Atlas.Toggles -Times 1 -Exactly -ParameterFilter {
            ($Text -join ' ') -like '*Windows Fax and Scan*'
        }
        # The partial line already tells the user; the diagnostic goes to the log only.
        Should -Invoke Write-AtlasLog -ModuleName Atlas.Toggles -Times 2 -Exactly -ParameterFilter {
            $Level -eq 'Warning' -and $NoConsole
        }
    }

    It 'still fails when a printing feature cannot be enabled' {
        Mock Invoke-AtlasToggleNativeCommand -ModuleName Atlas.Toggles {
            if ($ArgumentList -contains '/FeatureName:Printing-Foundation-Features') {
                throw 'feature failed'
            }
        }

        { Invoke-PrintingMachineAction } | Should -Throw '*feature failed*'
        Should -Not -Invoke Invoke-AtlasToggleNativeCommand -ModuleName Atlas.Toggles -ParameterFilter {
            $ArgumentList -contains '/Add-Capability'
        }
    }
}
