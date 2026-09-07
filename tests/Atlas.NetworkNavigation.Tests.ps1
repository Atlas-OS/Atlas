BeforeAll {
    . (Join-Path $PSScriptRoot 'AtlasTestHost.ps1')
    foreach ($module in 'Atlas.Core', 'Atlas.Registry', 'Atlas.Toggles', 'Atlas.Tweaks') {
        Import-Module (Join-Path $script:AtlasTestModulesRoot "$module\$module.psd1") -Force
    }
    $script:payloadRoot = Split-Path -Parent $script:AtlasTestScriptsRoot
    . (Join-Path $script:payloadRoot 'Toggles\General\FileSharing.ps1')
}

Describe 'Independent Explorer Network choice' {
    BeforeEach {
        Mock Read-AtlasYesNo { $false }
        Mock Invoke-AtlasToggle {}
    }

    It 'does not change visibility during service replay or when the optional choice is declined' {
        Add-AtlasFileSharingNetworkNavigationPane ([pscustomobject]@{ Silent = $true; StateRoot = 'HKCU:\TestState' })
        Should -Invoke Read-AtlasYesNo -Times 0 -Exactly
        Add-AtlasFileSharingNetworkNavigationPane ([pscustomobject]@{ Silent = $false; StateRoot = 'HKCU:\TestState' })
        Should -Invoke Invoke-AtlasToggle -Times 0 -Exactly
    }

    It 'uses the recording and replay owner when the user requests Network visibility' {
        Mock Read-AtlasYesNo { $true }
        Add-AtlasFileSharingNetworkNavigationPane ([pscustomobject]@{ Silent = $false; StateRoot = 'HKCU:\TestState' })
        Should -Invoke Invoke-AtlasToggle -Times 1 -Exactly -ParameterFilter {
            $Name -ceq 'NetworkNavigationPane' -and $State -ceq 'Enable' -and $StateRoot -eq 'HKCU:\TestState' -and $NoExplorerRestart -and $DeferPostAction
        }
    }

    It 'propagates failure to apply or record the optional visibility choice' {
        Mock Read-AtlasYesNo { $true }
        Mock Invoke-AtlasToggle { throw 'navigation choice failed' }
        { Add-AtlasFileSharingNetworkNavigationPane ([pscustomobject]@{ Silent = $false; StateRoot = 'HKCU:\TestState' }) } | Should -Throw '*navigation choice failed*'
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
