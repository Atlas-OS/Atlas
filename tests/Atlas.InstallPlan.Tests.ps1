BeforeAll {
    . (Join-Path $PSScriptRoot 'AtlasTestHost.ps1')
    $planScript = Join-Path $PSScriptRoot '..\playbook\Executables\AtlasModules\Scripts\Install\Install-Plan.ps1'
    . $planScript
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

    It 'replays lifecycle checkpoints and payload synchronization' {
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
    }

    It 'runs every standalone tweak step once with a well-formed slug' {
        $steps = @(
            Get-AtlasInstallPlan -Mode Fresh -IsOobe $false
            Get-AtlasInstallPlan -Mode Upgrade -IsOobe $false
            Get-AtlasInstallPlan -Mode Reapply -IsOobe $false
        ) | Where-Object { $_.Key.StartsWith('Tweak/', [StringComparison]::Ordinal) }

        @($steps.Key | Sort-Object -Unique) | Should -Be @(
            'Tweak/qol/appearance/atlas-theme-upgrade',
            'Tweak/qol/set-hidden-settings-pages',
            'Tweak/scripts/set-power-settings'
        )
        foreach ($step in $steps) {
            $step.Replay | Should -BeExactly 'Once'
            $step.Key.Substring('Tweak/'.Length) | Should -Match '^[a-z0-9-]+(/[a-z0-9-]+)+$'
        }
    }
}
