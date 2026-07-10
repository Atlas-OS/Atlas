BeforeAll {
    $script:scriptsRoot = Join-Path -Path $PSScriptRoot -ChildPath '..\playbook\Executables\AtlasModules\Scripts'
    $script:launcherPath = Join-Path -Path $script:scriptsRoot -ChildPath 'Set-FileAssociationsLauncher.cmd'
    $script:implementationPath = Join-Path -Path $script:scriptsRoot -ChildPath 'Internal\Set-FileAssociations.ps1'
    $script:tweakRoot = Join-Path -Path $script:scriptsRoot -ChildPath 'Tweaks\scripts'
    $script:companionPath = Join-Path -Path $script:tweakRoot -ChildPath 'set-file-associations.ps1'
    $script:definitionPath = Join-Path -Path $script:tweakRoot -ChildPath 'set-file-associations.psd1'
}

Describe 'File-association privilege boundary' {
    It 'does not enumerate or write arbitrary loaded user hives' {
        $launcher = Get-Content -LiteralPath $script:launcherPath -Raw
        $implementation = Get-Content -LiteralPath $script:implementationPath -Raw

        $launcher | Should -Not -Match '(?i)reg\s+(?:query|add)\s+"?HKU|HKEY_USERS|AME_UserHive'
        $implementation | Should -Not -Match '(?i)HKU:|HKEY_USERS|AME_UserHive|New-PSDrive.+Registry'
        $implementation | Should -Match 'Registry\]::CurrentUser'
        $implementation | Should -Not -Match '(?i)Registry\]::Users|Registry\]::ClassesRoot|Registry\]::LocalMachine\.(?:CreateSubKey|OpenSubKey\(.+,\s*\$true)'
    }

    It 'does not bypass protected UserChoice defaults with hashes or a renamed executable' {
        $launcher = Get-Content -LiteralPath $script:launcherPath -Raw
        $implementation = Get-Content -LiteralPath $script:implementationPath -Raw

        $launcher | Should -Not -Match '(?i)UCPD|powershellTemp|copy\s+/y.+powershell'
        $implementation | Should -Not -Match '(?i)UserChoice|Get-Hash|Shell32\.dll|RegDeleteKey|MD5CryptoServiceProvider'
        $implementation | Should -Not -Match '(?i)BraveHTML|FirefoxURL|ChromeHTML|LibreWolfHTM|UrlAssociations|FileExts'
    }

    It 'runs the companion as the explicit non-elevated interactive user' {
        $definition = Import-PowerShellDataFile -LiteralPath $script:definitionPath
        $definition['RunAs'] | Should -BeExactly 'User'
        $definition['RunAs'] | Should -Not -BeExactly 'UserElevated'
    }

    It 'uses the protected canonical PowerShell executable without renaming it' {
        $launcher = Get-Content -LiteralPath $script:launcherPath -Raw
        $launcher | Should -Match '%AtlasWindowsRoot%\\System32\\WindowsPowerShell\\v1\.0\\powershell\.exe'
        $launcher | Should -Match '-File "%assocScript%" -AssociationProfile "%profile%"'
        $launcher | Should -Not -Match '(?i)\bwhere\s+powershell(?:\.exe)?|%\*'
    }

    It 'rejects an unknown association profile before planning or applying changes' {
        { & $script:implementationPath -AssociationProfile 'Unknown Browser' -PlanOnly } |
            Should -Throw '*ValidateSet*'
    }

    It 'invokes the implementation directly from the user-scoped tweak companion' {
        $companion = Get-Content -LiteralPath $script:companionPath -Raw

        $companion | Should -Match 'Internal\\Set-FileAssociations\.ps1'
        $companion | Should -Match '& \$implementation -AssociationProfile ''Base'''
        $companion | Should -Match 'Protected browser defaults remain user-controlled'
        $companion | Should -Not -Match '(?i)Set-FileAssociationsLauncher\.cmd|TrustedInstaller|HKEY_USERS|HKU:|Test-AtlasOption|Atlas\.Core|active\.json'
    }

    It 'rejects service, session-zero, and elevated apply contexts' {
        $implementation = Get-Content -LiteralPath $script:implementationPath -Raw

        $implementation | Should -Match "S-1-5-18.+S-1-5-19.+S-1-5-20"
        $implementation | Should -Match "S-1-5-80-\*"
        $implementation | Should -Match 'SessionId -eq 0'
        $implementation | Should -Match 'WindowsBuiltInRole\]::Administrator'
        $implementation.IndexOf('if ($PlanOnly)') | Should -BeLessThan $implementation.LastIndexOf('Assert-IntendedInteractiveUser')
    }

    It 'captures exact value data and type and rolls changed values back in reverse order' {
        $implementation = Get-Content -LiteralPath $script:implementationPath -Raw

        $implementation | Should -Match 'RegistryValueOptions\]::DoNotExpandEnvironmentNames'
        $implementation | Should -Match 'GetValueKind\(\$Change\.Name\)'
        $implementation | Should -Match 'MissingPaths = \$missingPaths'
        $implementation | Should -Match 'for \(\$index = \$snapshots\.Count - 1; \$index -ge 0; \$index--\)'
        $implementation | Should -Match 'Restore-CurrentUserRegistryValue -Snapshot \$snapshots\[\$index\]'
    }

    It 'classifies protected browser defaults without writing them in plan-only mode' {
        $plan = & $script:implementationPath -AssociationProfile 'Firefox' -PlanOnly

        $plan.Mode | Should -BeExactly 'PlanOnly'
        $plan.Profile | Should -BeExactly 'Firefox'
        $plan.BrowserDefaultRequested | Should -BeTrue
        $plan.BrowserDefaultDisposition | Should -BeExactly 'WindowsProtectedUserActionRequired'
        $plan.DefaultAppsSettingsUri | Should -BeExactly 'ms-settings:defaultapps'
        $plan.ManagedDevicePolicy | Should -BeExactly 'DefaultAssociationsConfiguration'
        $plan.FirstSignInProvisioning | Should -BeExactly 'Import-DefaultAppAssociations'
        $plan.HandlerRegistration | Should -BeExactly 'OpenWithProgidsOnly'
        @($plan.Changes | Where-Object Hive -ne 'CurrentUser').Count | Should -Be 0
        @($plan.Changes | Where-Object Value -Match 'Brave|Firefox|Chrome|LibreWolf|Edge').Count | Should -Be 0
        @($plan.Changes | Where-Object { $_.Path -notmatch '\\OpenWithProgids$|^SOFTWARE\\7-Zip\\Options$' }).Count | Should -Be 0
        @($plan.Changes | Where-Object { $_.Path -match '^SOFTWARE\\Classes\\\.' -and $_.Name -eq '' }).Count | Should -Be 0
    }

    It 'builds the base plan under the current PowerShell host without applying it' {
        $plan = & $script:implementationPath -PlanOnly

        $plan.Mode | Should -BeExactly 'PlanOnly'
        $plan.Profile | Should -BeExactly 'Base'
        $plan.BrowserDefaultRequested | Should -BeFalse
        $plan.Rollback | Should -BeExactly 'ExactValueSnapshotOnError'
    }

    It 'represents an available handler as an empty OpenWithProgids registration' {
        $change = & {
            . $script:implementationPath -PlanOnly | Out-Null
            New-RegistryValuePlan `
                -Path 'SOFTWARE\Classes\.atlas-test\OpenWithProgids' `
                -Name 'Atlas.Test' `
                -Value '' `
                -Kind ([Microsoft.Win32.RegistryValueKind]::String)
        }

        $change.Hive | Should -BeExactly 'CurrentUser'
        $change.Path | Should -BeExactly 'SOFTWARE\Classes\.atlas-test\OpenWithProgids'
        $change.Name | Should -BeExactly 'Atlas.Test'
        $change.Value | Should -BeExactly ''
        $change.Kind | Should -Be ([Microsoft.Win32.RegistryValueKind]::String)
    }
}
