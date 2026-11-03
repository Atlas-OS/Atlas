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
                'Tweak/scripts/set-power-settings', 'Checkpoint/WindowsTransition', 'Checkpoint/InstallingUserSetup',
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
                'Checkpoint/WindowsTransition', 'Checkpoint/NotificationRestore', 'Checkpoint/DefaultHiveUnload'
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
                'Checkpoint/WindowsTransition', 'Checkpoint/InstallingUserSetup',
                'Checkpoint/NotificationRestore', 'Checkpoint/DefaultHiveUnload'
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
                'Checkpoint/WindowsTransition', 'Checkpoint/NotificationRestore', 'Checkpoint/DefaultHiveUnload'
            )
        }
        @{
            Mode = 'Rebase'; IsOobe = $false; Expected = @(
                'Checkpoint/DefaultHiveLoad', 'Checkpoint/PayloadReplacement',
                'Checkpoint/NotificationDisable', 'Checkpoint/RebaseRecovery', 'Checkpoint/LegacyChoices',
                'PreInstall', 'ShellRefresh', 'Environment',
                'Checkpoint/InitializePath', 'Features', 'Software', 'Services', 'Components', 'AppxSupport', 'Defaults',
                'Tweak/qol/appearance/atlas-theme-upgrade',
                'Tweaks/networking', 'Tweaks/performance', 'Tweaks/privacy', 'Tweaks/qol',
                'Tweaks/security', 'Tweaks/debloat', 'Tweaks/scripts', 'Tweaks/misc',
                'Checkpoint/WindowsTransition', 'Checkpoint/InstallingUserSetup',
                'Checkpoint/NotificationRestore', 'Checkpoint/DefaultHiveUnload'
            )
        }
        # A reinstall of the same version runs the tweak categories and the installing
        # user's setup as well, so a new build's fixes arrive.
        @{
            Mode = 'Reapply'; IsOobe = $false; Expected = @(
                'Checkpoint/DefaultHiveLoad', 'Checkpoint/PayloadReplacement',
                'Checkpoint/NotificationDisable', 'PreInstall', 'ShellRefresh', 'Environment',
                'Checkpoint/InitializePath', 'Features', 'Software', 'Defaults',
                'Tweaks/networking', 'Tweaks/performance', 'Tweaks/privacy', 'Tweaks/qol',
                'Tweaks/security', 'Tweaks/debloat', 'Tweaks/scripts', 'Tweaks/misc',
                'Checkpoint/WindowsTransition', 'Checkpoint/InstallingUserSetup',
                'Checkpoint/NotificationRestore', 'Checkpoint/DefaultHiveUnload'
            )
        }
        @{
            Mode = 'Reapply'; IsOobe = $true; Expected = @(
                'Checkpoint/DefaultHiveLoad', 'Checkpoint/PayloadReplacement',
                'Checkpoint/NotificationDisable', 'PreInstall', 'Environment',
                'Checkpoint/InitializePath', 'Features', 'Software', 'Defaults',
                'Tweaks/networking', 'Tweaks/performance', 'Tweaks/privacy', 'Tweaks/qol',
                'Tweaks/security', 'Tweaks/debloat', 'Tweaks/scripts', 'Tweaks/misc',
                'Checkpoint/WindowsTransition', 'Checkpoint/NotificationRestore', 'Checkpoint/DefaultHiveUnload'
            )
        }
    ) {
        @((Get-AtlasInstallPlan -Mode $Mode -IsOobe $IsOobe).Key) |
            Should -Be $Expected
    }

    It 'adds the Choices step when choosing again on <Mode>' -TestCases @(
        @{
            Mode = 'Upgrade'; Expected = @(
                'Checkpoint/DefaultHiveLoad', 'Checkpoint/PayloadReplacement',
                'Checkpoint/NotificationDisable', 'Checkpoint/LegacyChoices', 'PreInstall', 'ShellRefresh', 'Environment',
                'Checkpoint/InitializePath', 'Features', 'Software', 'Choices', 'Defaults',
                'Tweak/qol/appearance/atlas-theme-upgrade',
                'Tweaks/networking', 'Tweaks/performance', 'Tweaks/privacy', 'Tweaks/qol',
                'Tweaks/security', 'Tweaks/debloat', 'Tweaks/scripts', 'Tweaks/misc',
                'Checkpoint/WindowsTransition', 'Checkpoint/InstallingUserSetup',
                'Checkpoint/NotificationRestore', 'Checkpoint/DefaultHiveUnload'
            )
        }
        @{
            Mode = 'Reapply'; Expected = @(
                'Checkpoint/DefaultHiveLoad', 'Checkpoint/PayloadReplacement',
                'Checkpoint/NotificationDisable', 'PreInstall', 'ShellRefresh', 'Environment',
                'Checkpoint/InitializePath', 'Features', 'Software', 'Choices', 'Defaults',
                'Tweaks/networking', 'Tweaks/performance', 'Tweaks/privacy', 'Tweaks/qol',
                'Tweaks/security', 'Tweaks/debloat', 'Tweaks/scripts', 'Tweaks/misc',
                'Checkpoint/WindowsTransition', 'Checkpoint/InstallingUserSetup',
                'Checkpoint/NotificationRestore', 'Checkpoint/DefaultHiveUnload'
            )
        }
    ) {
        param($Mode, $Expected)
        @((Get-AtlasInstallPlan -Mode $Mode -IsOobe $false -ChooseAgain $true).Key) | Should -Be $Expected
        # Only the front door and Atlas Manager choose again, and never during
        # Windows setup, so the step doesn't run without a user.
        @((Get-AtlasInstallPlan -Mode $Mode -IsOobe $true -ChooseAgain $true).Key) |
            Should -Be @((Get-AtlasInstallPlan -Mode $Mode -IsOobe $true).Key)
    }

    It 'keeps the <Mode> plan the same with or without choosing again, OOBE=<IsOobe>' -TestCases @(
        @{ Mode = 'Fresh'; IsOobe = $false }, @{ Mode = 'Fresh'; IsOobe = $true }
        @{ Mode = 'Rebase'; IsOobe = $false }, @{ Mode = 'Rebase'; IsOobe = $true }
    ) {
        param($Mode, $IsOobe)
        @((Get-AtlasInstallPlan -Mode $Mode -IsOobe $IsOobe -ChooseAgain $true).Key) |
            Should -Be @((Get-AtlasInstallPlan -Mode $Mode -IsOobe $IsOobe).Key)
    }

    It 'runs Choices on <Mode> after the legacy choices and the software, and before every replay or tweak' -TestCases @(
        @{ Mode = 'Upgrade' }, @{ Mode = 'Reapply' }
    ) {
        param($Mode)
        # A new browser and the old choices come first; the replay and the tweaks that
        # keep a recorded choice then apply the records Choices writes.
        $keys = @((Get-AtlasInstallPlan -Mode $Mode -IsOobe $false -ChooseAgain $true).Key)
        $choices = [array]::IndexOf($keys, 'Choices')
        $choices | Should -BeGreaterThan -1
        foreach ($earlier in @('Checkpoint/LegacyChoices', 'Software')) {
            if ($keys -contains $earlier) { [array]::IndexOf($keys, $earlier) | Should -BeLessThan $choices -Because $earlier }
        }
        $later = @($keys | Where-Object { $_ -ceq 'Defaults' -or $_.StartsWith('Tweak', [StringComparison]::Ordinal) })
        $later.Count | Should -BeGreaterThan 8
        foreach ($key in $later) {
            [array]::IndexOf($keys, $key) | Should -BeGreaterThan $choices -Because $key
        }
    }

    It 'gives every step its choose-again modes, empty unless it applies the choices' {
        $steps = @(foreach ($mode in 'Fresh', 'Upgrade', 'Reapply', 'Rebase') {
                Get-AtlasInstallPlan -Mode $mode -IsOobe $false -ChooseAgain $true
            }) | Sort-Object Key -Unique
        foreach ($step in $steps) {
            $expected = if ($step.Key -ceq 'Choices') { @('Upgrade', 'Reapply') } else { @() }
            @($step.ChooseAgainModes) | Should -Be $expected -Because $step.Key
        }
        (@($steps | Where-Object Key -ceq 'Choices')[0]).Modes | Should -HaveCount 0 -Because 'only choosing again runs it'
    }

    It 'replays lifecycle checkpoints and file synchronization' {
        $steps = @(
            Get-AtlasInstallPlan -Mode Fresh -IsOobe $false
            Get-AtlasInstallPlan -Mode Fresh -IsOobe $true
            Get-AtlasInstallPlan -Mode Upgrade -IsOobe $false
            Get-AtlasInstallPlan -Mode Upgrade -IsOobe $true
            Get-AtlasInstallPlan -Mode Reapply -IsOobe $false
            Get-AtlasInstallPlan -Mode Reapply -IsOobe $true
            Get-AtlasInstallPlan -Mode Upgrade -IsOobe $false -ChooseAgain $true
            Get-AtlasInstallPlan -Mode Reapply -IsOobe $false -ChooseAgain $true
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

    It 'captures legacy choices before any phase or tweak runs on upgrade, OOBE=<IsOobe>, choosing again <ChooseAgain>' -TestCases @(
        @{ IsOobe = $false; ChooseAgain = $false }
        @{ IsOobe = $true; ChooseAgain = $false }
        @{ IsOobe = $false; ChooseAgain = $true }
    ) {
        # The capture reads the live registry, so anything that writes defaults first
        # erases the evidence of the user's earlier choices.
        $keys = @((Get-AtlasInstallPlan -Mode Upgrade -IsOobe $IsOobe -ChooseAgain $ChooseAgain).Key)
        $capture = [array]::IndexOf($keys, 'Checkpoint/LegacyChoices')
        $capture | Should -BeGreaterThan -1
        foreach ($key in $keys | Where-Object { -not $_.StartsWith('Checkpoint/', [StringComparison]::Ordinal) }) {
            [array]::IndexOf($keys, $key) | Should -BeGreaterThan $capture -Because $key
        }
    }
}
