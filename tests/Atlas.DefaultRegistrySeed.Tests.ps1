BeforeAll {
    . (Join-Path $PSScriptRoot 'AtlasTestHost.ps1')
    $script:repoRoot = $script:AtlasTestRepoRoot
    $script:scriptsRoot = $script:AtlasTestScriptsRoot
    . (Join-Path $script:scriptsRoot 'Install\Install-Plan.ps1')
    foreach ($module in 'Atlas.Core', 'Atlas.Registry', 'Atlas.Toggles', 'Atlas.Tweaks') {
        Import-Module (Join-Path $script:AtlasTestModulesRoot "$module\$module.psd1") -Force
    }
}

Describe 'Applied toggle defaults' {
    It 'does not seed unapplied toggle choices on fresh installs' {
        Test-Path (Join-Path $script:repoRoot 'playbook\Executables\DEFAULT.reg') | Should -BeFalse
        @(Get-AtlasInstallPlan -Mode Fresh).Key | Should -Not -Contain 'Checkpoint/DefaultRegistrySeed'
    }

    It 'applies and records the three privacy defaults through the toggle engine' {
        Mock -ModuleName Atlas.Tweaks Invoke-AtlasToggleMachineState {}
        Mock -ModuleName Atlas.Tweaks Write-AtlasLog {}
        $context = [pscustomobject]@{ IsUpgrade = $false; IsOobe = $false; IsArm64 = $false; WindowsBuild = 26200 }
        $root = Join-Path $script:scriptsRoot 'Tweaks'
        $manifest = Get-AtlasTweakManifest -Path (Join-Path $root 'tweaks.manifest.psd1')
        @($manifest.Categories | Where-Object Name -eq 'privacy').Tweaks | Should -Contain 'apply-privacy-toggle-defaults'
        $path = Join-Path $root 'privacy\apply-privacy-toggle-defaults.psd1'
        @(Test-AtlasTweakSchema -Path $path).Count | Should -Be 0
        Invoke-AtlasTweak -Path $path -Context $context
        Should -Invoke -ModuleName Atlas.Tweaks Invoke-AtlasToggleMachineState -Times 3 -Exactly
        foreach ($toggleName in 'PhoneLink', 'RecentItems', 'WebSearch') {
            Should -Invoke -ModuleName Atlas.Tweaks Invoke-AtlasToggleMachineState -Times 1 -Exactly -ParameterFilter {
                $Name -ceq $toggleName -and $State -ceq 'Disable'
            }
        }
    }
}
