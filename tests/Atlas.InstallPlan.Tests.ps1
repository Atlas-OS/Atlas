BeforeAll {
    . (Join-Path $PSScriptRoot 'AtlasTestHost.ps1')
    . (Join-Path $script:AtlasTestScriptsRoot 'Install\Install-Plan.ps1')
}

Describe 'Atlas install plan' {
    It 'returns the exact ordered <Mode> OOBE=<IsOobe> plan' -TestCases @(
        @{
            Mode = 'Fresh'; IsOobe = $false; Expected = @(
                'Checkpoint/DefaultHiveLoad', 'Checkpoint/PayloadReplacement',
                'Checkpoint/NotificationDisable', 'PreInstall', 'ShellRefresh', 'Environment',
                'Tweak/qol/set-hidden-settings-pages', 'Checkpoint/InitializePath', 'Features', 'Software',
                'Services', 'Components', 'AppxSupport', 'Defaults',
                'Tweaks/networking', 'Tweaks/performance', 'Tweaks/privacy', 'Tweaks/qol',
                'Tweaks/security', 'Tweaks/debloat', 'Tweaks/scripts', 'Tweaks/misc',
                'Tweak/scripts/set-power-settings', 'Checkpoint/InstallingUserSetup',
                'Checkpoint/NotificationRestore', 'Checkpoint/DefaultHiveUnload'
            )
        }
        @{
            Mode = 'Fresh'; IsOobe = $true; Expected = @(
                'Checkpoint/DefaultHiveLoad', 'Checkpoint/PayloadReplacement',
                'Checkpoint/NotificationDisable', 'PreInstall', 'Environment',
                'Tweak/qol/set-hidden-settings-pages', 'Checkpoint/InitializePath',
                'Features', 'Software', 'Services', 'Components', 'AppxSupport', 'Defaults',
                'Tweaks/networking', 'Tweaks/performance',
                'Tweaks/privacy', 'Tweaks/qol', 'Tweaks/security', 'Tweaks/debloat',
                'Tweaks/scripts', 'Tweaks/misc', 'Tweak/scripts/set-power-settings',
                'Checkpoint/NotificationRestore', 'Checkpoint/DefaultHiveUnload'
            )
        }
        @{
            Mode = 'Upgrade'; IsOobe = $false; Expected = @(
                'Checkpoint/DefaultHiveLoad', 'Checkpoint/PayloadReplacement',
                'Checkpoint/NotificationDisable', 'Checkpoint/LegacyChoices', 'PreInstall', 'ShellRefresh', 'Environment',
                'Checkpoint/InitializePath', 'Features', 'Software', 'Defaults',
                'Tweak/qol/appearance/atlas-theme-upgrade',
                'Tweaks/networking', 'Tweaks/performance', 'Tweaks/privacy', 'Tweaks/qol',
                'Tweaks/security', 'Tweaks/debloat', 'Tweaks/scripts', 'Tweaks/misc',
                'Checkpoint/InstallingUserSetup',
                'Checkpoint/OemBranding', 'Checkpoint/NotificationRestore',
                'Checkpoint/DefaultHiveUnload'
            )
        }
        @{
            Mode = 'Upgrade'; IsOobe = $true; Expected = @(
                'Checkpoint/DefaultHiveLoad', 'Checkpoint/PayloadReplacement',
                'Checkpoint/NotificationDisable', 'Checkpoint/LegacyChoices', 'PreInstall', 'Environment',
                'Checkpoint/InitializePath', 'Features', 'Software', 'Defaults',
                'Tweak/qol/appearance/atlas-theme-upgrade',
                'Tweaks/networking', 'Tweaks/performance', 'Tweaks/privacy', 'Tweaks/qol',
                'Tweaks/security', 'Tweaks/debloat', 'Tweaks/scripts', 'Tweaks/misc',
                'Checkpoint/OemBranding', 'Checkpoint/NotificationRestore',
                'Checkpoint/DefaultHiveUnload'
            )
        }
        @{
            Mode = 'Reapply'; IsOobe = $false; Expected = @(
                'Checkpoint/DefaultHiveLoad', 'Checkpoint/PayloadReplacement',
                'Checkpoint/NotificationDisable', 'PreInstall', 'ShellRefresh', 'Environment',
                'Checkpoint/InitializePath', 'Features', 'Software', 'Defaults',
                'Checkpoint/NotificationRestore', 'Checkpoint/DefaultHiveUnload'
            )
        }
        @{
            Mode = 'Reapply'; IsOobe = $true; Expected = @(
                'Checkpoint/DefaultHiveLoad', 'Checkpoint/PayloadReplacement',
                'Checkpoint/NotificationDisable', 'PreInstall', 'Environment',
                'Checkpoint/InitializePath', 'Features', 'Software', 'Defaults',
                'Checkpoint/NotificationRestore', 'Checkpoint/DefaultHiveUnload'
            )
        }
    ) {
        @((Get-AtlasInstallPlan -Mode $Mode -IsOobe $IsOobe).Key) |
            Should -Be $Expected
    }

    It 'replays lifecycle checkpoints and file synchronization' {
        $steps = @(
            Get-AtlasInstallPlan -Mode Fresh -IsOobe $false
            Get-AtlasInstallPlan -Mode Fresh -IsOobe $true
            Get-AtlasInstallPlan -Mode Upgrade -IsOobe $false
            Get-AtlasInstallPlan -Mode Upgrade -IsOobe $true
            Get-AtlasInstallPlan -Mode Reapply -IsOobe $false
            Get-AtlasInstallPlan -Mode Reapply -IsOobe $true
        ) | Sort-Object Key -Unique

        @($steps | Where-Object Replay -eq Always | ForEach-Object Key) |
            Should -Be @(
                'Checkpoint/DefaultHiveLoad',
                'Checkpoint/DefaultHiveUnload',
                'Checkpoint/NotificationDisable',
                'Checkpoint/NotificationRestore',
                'Checkpoint/PayloadReplacement'
            )
        foreach ($step in $steps) {
            $step.Replay | Should -BeIn @('Once', 'Always') -Because $step.Key
        }
    }

    It 'captures legacy choices before any phase or tweak runs on upgrade, OOBE=<IsOobe>' -TestCases @(
        @{ IsOobe = $false }
        @{ IsOobe = $true }
    ) {
        # The capture reads the live registry, so anything that writes defaults first
        # erases the evidence of the user's earlier choices.
        $keys = @((Get-AtlasInstallPlan -Mode Upgrade -IsOobe $IsOobe).Key)
        $capture = [array]::IndexOf($keys, 'Checkpoint/LegacyChoices')
        $capture | Should -BeGreaterThan -1
        foreach ($key in $keys | Where-Object { -not $_.StartsWith('Checkpoint/', [StringComparison]::Ordinal) }) {
            [array]::IndexOf($keys, $key) | Should -BeGreaterThan $capture -Because $key
        }
    }
}
