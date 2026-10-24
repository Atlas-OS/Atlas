BeforeAll {
    . (Join-Path $PSScriptRoot 'AtlasTestHost.ps1')
    foreach ($module in 'Atlas.Core', 'Atlas.Registry', 'Atlas.Toggles', 'Atlas.Tweaks') {
        Import-Module (Join-Path $script:AtlasTestModulesRoot "$module\$module.psd1") -Force
    }
    $script:payloadRoot = Split-Path -Parent $script:AtlasTestScriptsRoot
    $script:fileSharing = Get-AtlasToggleDefinition -Name FileSharing -TogglesRoot (Join-Path $script:payloadRoot 'Toggles')

    # Runs the Enable user action the way the engine does: with the engine's own
    # $Toggle context, dot-sourced inside Atlas.Toggles under strict mode.
    function Invoke-NetworkPaneChoice {
        param([bool]$Silent)

        InModuleScope Atlas.Toggles {
            $context = New-AtlasToggleContext -Definition $d -StateName 'Enable' -Silent:$silent -StateRoot 'HKCU:\TestState'
            Invoke-AtlasToggleFunction -Definition $d -FunctionName ([string]$d['States']['Enable']['UserAction']) `
                -Toggle $context -Label 'test'
        } -Parameters @{ d = $script:fileSharing; silent = $Silent }
    }
}

Describe 'Independent Explorer Network choice' {
    BeforeEach {
        Mock Read-AtlasYesNo -ModuleName Atlas.Toggles { $false }
        Mock Invoke-AtlasToggle -ModuleName Atlas.Toggles {}
    }

    It 'does not change visibility during service replay or when the optional choice is declined' {
        Invoke-NetworkPaneChoice -Silent $true
        Should -Invoke Read-AtlasYesNo -ModuleName Atlas.Toggles -Times 0 -Exactly
        Invoke-NetworkPaneChoice -Silent $false
        Should -Invoke Read-AtlasYesNo -ModuleName Atlas.Toggles -Times 1 -Exactly
        Should -Invoke Invoke-AtlasToggle -ModuleName Atlas.Toggles -Times 0 -Exactly
    }

    It 'uses the recording and replay owner when the user requests Network visibility' {
        Mock Read-AtlasYesNo -ModuleName Atlas.Toggles { $true }
        Invoke-NetworkPaneChoice -Silent $false
        Should -Invoke Invoke-AtlasToggle -ModuleName Atlas.Toggles -Times 1 -Exactly -ParameterFilter {
            $Name -ceq 'NetworkNavigationPane' -and $State -ceq 'Enable' -and $StateRoot -eq 'HKCU:\TestState' -and $NoExplorerRestart -and $DeferPostAction
        }
    }

    It 'keeps the fresh hidden default and detects a failed explicit visibility choice' {
        $path = Join-Path $script:AtlasTestScriptsRoot 'Tweaks\qol\explorer\disable-network-navigation-pane.psd1'
        Mock -ModuleName Atlas.Registry Get-AtlasRegistryValueState {
            [pscustomobject]@{ KeyExists = $true; ValueExists = $true; Kind = 'DWord'; Data = 0 }
        }
        $context = [pscustomobject]@{ IsArm64 = $false; WindowsBuild = 26200; IsUpgrade = $false; IsOobe = $false; Options = @() }
        @(Test-AtlasTweak -Path $path -RegistryScope CurrentUser -Context $context).Count | Should -Be 0
        $drift = @(Test-AtlasTweak -Path $path -RegistryScope CurrentUser -Context $context -RecordedToggleStates @{ NetworkNavigationPane = 1 })
        $drift.Count | Should -Be 1
        $drift[0].Reason | Should -Be 'value still exists'
        Mock -ModuleName Atlas.Registry Get-AtlasRegistryValueState {
            [pscustomobject]@{ KeyExists = $true; ValueExists = $false; Kind = $null; Data = $null }
        }
        @(Test-AtlasTweak -Path $path -RegistryScope CurrentUser -Context $context -RecordedToggleStates @{ NetworkNavigationPane = 1 }).Count | Should -Be 0
    }
}
