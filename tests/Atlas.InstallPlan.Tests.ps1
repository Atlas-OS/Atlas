BeforeAll {
    $planScript = Join-Path $PSScriptRoot '..\playbook\Executables\AtlasModules\Scripts\Internal\Install-Plan.ps1'
    . $planScript
}

Describe 'Atlas install plan' {
    It 'returns the exact ordered <Mode> OOBE=<IsOobe> plan' -TestCases @(
        @{
            Mode = 'Fresh'; IsOobe = $false; Expected = @(
                'Checkpoint/DefaultHiveLoad', 'Checkpoint/PayloadReplacement',
                'Checkpoint/NotificationDisable', 'PreInstall', 'ShellRefresh', 'Environment',
                'Checkpoint/HiddenSettingsPages', 'Checkpoint/InitializePath', 'Features', 'Software',
                'Services', 'Components', 'AppxSupport', 'Defaults', 'Checkpoint/DefaultRegistrySeed',
                'Tweaks/networking', 'Tweaks/performance', 'Tweaks/privacy', 'Tweaks/qol',
                'Tweaks/security', 'Tweaks/debloat', 'Tweaks/scripts', 'Tweaks/misc',
                'Checkpoint/PowerSettings', 'Checkpoint/InstallingUserSetup',
                'Checkpoint/NotificationRestore', 'Checkpoint/DefaultHiveUnload'
            )
        }
        @{
            Mode = 'Fresh'; IsOobe = $true; Expected = @(
                'Checkpoint/PayloadReplacement', 'Checkpoint/NotificationDisable', 'PreInstall',
                'Environment', 'Checkpoint/HiddenSettingsPages', 'Checkpoint/InitializePath',
                'Features', 'Software', 'Services', 'Components', 'AppxSupport', 'Defaults',
                'Checkpoint/DefaultRegistrySeed', 'Checkpoint/PowerSettings',
                'Checkpoint/NotificationRestore'
            )
        }
        @{
            Mode = 'Upgrade'; IsOobe = $false; Expected = @(
                'Checkpoint/DefaultHiveLoad', 'Checkpoint/PayloadReplacement',
                'Checkpoint/NotificationDisable', 'PreInstall', 'ShellRefresh', 'Environment',
                'Checkpoint/InitializePath', 'Features', 'Software', 'Defaults', 'Revert',
                'Checkpoint/OemBranding', 'Checkpoint/NotificationRestore',
                'Checkpoint/DefaultHiveUnload'
            )
        }
        @{
            Mode = 'Upgrade'; IsOobe = $true; Expected = @(
                'Checkpoint/PayloadReplacement', 'Checkpoint/NotificationDisable', 'PreInstall',
                'Environment', 'Checkpoint/InitializePath', 'Features', 'Software', 'Defaults',
                'Revert', 'Checkpoint/OemBranding', 'Checkpoint/NotificationRestore'
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
                'Checkpoint/PayloadReplacement', 'Checkpoint/NotificationDisable', 'PreInstall',
                'Environment', 'Checkpoint/InitializePath', 'Features', 'Software', 'Defaults',
                'Checkpoint/NotificationRestore'
            )
        }
    ) {
        @((Get-AtlasInstallPlan -Mode $Mode -IsOobe $IsOobe).Key) |
            Should -Be $Expected
    }

    It 'marks only lifecycle cleanup checkpoints for replay' {
        $steps = @(
            Get-AtlasInstallPlan -Mode Fresh -IsOobe $false
            Get-AtlasInstallPlan -Mode Upgrade -IsOobe $false
            Get-AtlasInstallPlan -Mode Reapply -IsOobe $false
        ) | Sort-Object Key -Unique

        @($steps | Where-Object Replay -eq Always | ForEach-Object Key) |
            Should -Be @(
                'Checkpoint/DefaultHiveLoad',
                'Checkpoint/DefaultHiveUnload',
                'Checkpoint/NotificationDisable',
                'Checkpoint/NotificationRestore'
            )
    }
}
