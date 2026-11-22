BeforeAll {
    . (Join-Path $PSScriptRoot 'AtlasTestHost.ps1')
    foreach ($module in 'Atlas.Core', 'Atlas.Registry', 'Atlas.Toggles', 'Atlas.Tweaks') {
        Import-Module (Join-Path $script:AtlasTestModulesRoot "$module\$module.psd1") -Force
    }
    $script:atlasModulesRoot = Split-Path -Parent $script:AtlasTestScriptsRoot
    $script:fileSharing = Get-AtlasToggleDefinition -Name FileSharing -TogglesRoot (Join-Path $script:atlasModulesRoot 'Toggles')

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
        $togglesRoot = Join-Path $script:atlasModulesRoot 'Toggles'
        # Tweak verification looks up recorded toggles under %windir%\AtlasModules by
        # default, so the test supplies the package's own definition.
        $script:networkPane = Get-AtlasToggleDefinition -Name NetworkNavigationPane -TogglesRoot $togglesRoot
        Mock -ModuleName Atlas.Tweaks Get-AtlasToggleDefinition { $script:networkPane } -ParameterFilter { $Name -ceq 'NetworkNavigationPane' }
        Mock -ModuleName Atlas.Tweaks Get-AtlasToggleDefinition { throw "No toggle definition named '$Name' was found." }
        Mock -ModuleName Atlas.Toggles Get-AtlasToggleStateRecords { @{ NetworkNavigationPane = 1 } }
        Mock -ModuleName Atlas.Registry Get-AtlasRegistryValueState {
            [pscustomobject]@{ KeyExists = $true; ValueExists = $true; Kind = 'DWord'; Data = 0 }
        }
        $context = [pscustomobject]@{ IsArm64 = $false; WindowsBuild = 26200; IsUpgrade = $false; Options = @() }
        @(Test-AtlasTweak -Path $path -RegistryScope CurrentUser -Context $context).Count | Should -Be 0

        # The recorded choice owns the value, so tweak verification leaves it to the
        # toggle, which finds Network still hidden.
        @(Test-AtlasTweak -Path $path -RegistryScope CurrentUser -Context $context -RecordedToggleStates @{ NetworkNavigationPane = 1 }).Count | Should -Be 0
        $toggleDrift = @(Test-AtlasToggleDrift -Scope User -TogglesRoot $togglesRoot)
        $toggleDrift.Count | Should -Be 1
        $toggleDrift[0].Toggle | Should -BeExactly 'NetworkNavigationPane'
        $toggleDrift[0].Reason | Should -Be 'value still exists'

        # Without a loadable definition, VerifyWithToggle still expects the recorded choice.
        Mock -ModuleName Atlas.Tweaks Get-AtlasToggleDefinition { throw "No toggle definition named '$Name' was found." } -ParameterFilter { $Name -ceq 'NetworkNavigationPane' }
        $drift = @(Test-AtlasTweak -Path $path -RegistryScope CurrentUser -Context $context -RecordedToggleStates @{ NetworkNavigationPane = 1 })
        $drift.Count | Should -Be 1
        $drift[0].Reason | Should -Be 'value still exists'

        Mock -ModuleName Atlas.Registry Get-AtlasRegistryValueState {
            [pscustomobject]@{ KeyExists = $true; ValueExists = $false; Kind = $null; Data = $null }
        }
        @(Test-AtlasTweak -Path $path -RegistryScope CurrentUser -Context $context -RecordedToggleStates @{ NetworkNavigationPane = 1 }).Count | Should -Be 0
        @(Test-AtlasToggleDrift -Scope User -TogglesRoot $togglesRoot).Count | Should -Be 0
    }
}
