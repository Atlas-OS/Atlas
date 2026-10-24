BeforeAll {
    . (Join-Path $PSScriptRoot 'AtlasTestHost.ps1')
    Import-Module (Join-Path $script:AtlasTestModulesRoot 'Atlas.Core\Atlas.Core.psd1') -Force
    Import-Module (Join-Path $script:AtlasTestModulesRoot 'Atlas.Shell\Atlas.Shell.psd1') -Force
    Import-Module (Join-Path $script:AtlasTestModulesRoot 'Atlas.Toggles\Atlas.Toggles.psd1') -Force

    $togglesRoot = Join-Path $script:AtlasTestRepoRoot 'playbook\Executables\AtlasModules\Toggles'
    $script:SendTo = Get-AtlasToggleDefinition -Name SendToContextMenu -TogglesRoot $togglesRoot

    # Runs the companion as the engine does (dot-sourced into the module scope under
    # strict mode), so module-scoped mocks, including private engine helpers, apply.
    function Invoke-SendToChooser {
        param([bool]$Silent)

        $toggle = [pscustomobject]@{ Name = 'SendToContextMenu'; State = 'Debloat'; Silent = $Silent }
        InModuleScope Atlas.Toggles {
            Invoke-AtlasToggleFunction -Definition $d -FunctionName 'Invoke-AtlasSendToContextMenuChooser' `
                -Toggle $t -Label 'test'
        } -Parameters @{ d = $script:SendTo; t = $toggle }
    }
}

Describe 'Send To companion' {
    BeforeEach {
        Mock Import-AtlasModule -ModuleName Atlas.Toggles
        Mock Write-AtlasStep -ModuleName Atlas.Toggles
        Mock Write-AtlasLog -ModuleName Atlas.Toggles
        Mock Write-AtlasPartial -ModuleName Atlas.Toggles
        Mock Write-AtlasNextStep -ModuleName Atlas.Toggles
        Mock Read-AtlasYesNo -ModuleName Atlas.Toggles { $true }
        # Like the real function, only the interactive dialog reports whether it applied.
        Mock Set-AtlasSendToContextMenu -ModuleName Atlas.Toggles { if (-not $DebloatDefaults) { $true } }
        Mock Invoke-AtlasToggleCurrentSessionShellRefresh -ModuleName Atlas.Toggles
        # An elevated window skips the restart question, so the test host's own token
        # mustn't decide these cases.
        Mock Test-AtlasAdmin -ModuleName Atlas.Toggles { $false }
        Mock Test-AtlasSystem -ModuleName Atlas.Toggles { $false }
    }

    It 'applies the Atlas defaults silently without asking or restarting Explorer' {
        @(Invoke-SendToChooser -Silent $true).Count | Should -Be 0

        Should -Invoke Set-AtlasSendToContextMenu -ModuleName Atlas.Toggles -Times 1 -Exactly -ParameterFilter { $DebloatDefaults }
        Should -Invoke Read-AtlasYesNo -ModuleName Atlas.Toggles -Times 0 -Exactly
        Should -Invoke Invoke-AtlasToggleCurrentSessionShellRefresh -ModuleName Atlas.Toggles -Times 0 -Exactly
    }

    It 'restarts Explorer through the engine helper after an applied choice' {
        @(Invoke-SendToChooser -Silent $false).Count | Should -Be 0

        Should -Invoke Read-AtlasYesNo -ModuleName Atlas.Toggles -Times 1 -Exactly -ParameterFilter { $DefaultYes }
        Should -Invoke Invoke-AtlasToggleCurrentSessionShellRefresh -ModuleName Atlas.Toggles -Times 1 -Exactly `
            -ParameterFilter { $Operation -ceq 'ExplorerRefresh' }
        Should -Invoke Write-AtlasPartial -ModuleName Atlas.Toggles -Times 0 -Exactly
        Should -Invoke Write-AtlasNextStep -ModuleName Atlas.Toggles -Times 0 -Exactly
    }

    It 'gives restart guidance instead of asking when run as <Account>' -ForEach @(
        @{ Account = 'an administrator'; Elevated = 'Test-AtlasAdmin' }
        @{ Account = 'SYSTEM'; Elevated = 'Test-AtlasSystem' }
    ) {
        Mock $Elevated -ModuleName Atlas.Toggles { $true }

        Invoke-SendToChooser -Silent $false

        Should -Invoke Read-AtlasYesNo -ModuleName Atlas.Toggles -Times 0 -Exactly
        Should -Invoke Invoke-AtlasToggleCurrentSessionShellRefresh -ModuleName Atlas.Toggles -Times 0 -Exactly
        Should -Invoke Write-AtlasNextStep -ModuleName Atlas.Toggles -Times 1 -Exactly
    }

    It 'neither asks nor restarts Explorer when the dialog is cancelled' {
        Mock Set-AtlasSendToContextMenu -ModuleName Atlas.Toggles { $false }

        Invoke-SendToChooser -Silent $false

        Should -Invoke Read-AtlasYesNo -ModuleName Atlas.Toggles -Times 0 -Exactly
        Should -Invoke Invoke-AtlasToggleCurrentSessionShellRefresh -ModuleName Atlas.Toggles -Times 0 -Exactly
    }

    It 'leaves Explorer alone when the restart is declined' {
        Mock Read-AtlasYesNo -ModuleName Atlas.Toggles { $false }

        Invoke-SendToChooser -Silent $false

        Should -Invoke Invoke-AtlasToggleCurrentSessionShellRefresh -ModuleName Atlas.Toggles -Times 0 -Exactly
    }

    It 'reports a failed Explorer restart as partly done instead of not applied' {
        Mock Invoke-AtlasToggleCurrentSessionShellRefresh -ModuleName Atlas.Toggles {
            throw 'Current-session toggle shell refresh exited with code 14.'
        }

        { Invoke-SendToChooser -Silent $false } | Should -Not -Throw

        Should -Invoke Write-AtlasPartial -ModuleName Atlas.Toggles -Times 1 -Exactly
        Should -Invoke Write-AtlasLog -ModuleName Atlas.Toggles -Times 1 -Exactly -ParameterFilter {
            $Level -ceq 'Warning' -and $Message -like '*exited with code 14*'
        }
    }
}
