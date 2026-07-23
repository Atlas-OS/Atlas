BeforeAll {
    function Import-FunctionUnderTest {
        param(
            [Parameter(Mandatory = $true)][string]$Path,
            [Parameter(Mandatory = $true)][string]$Name
        )

        $tokens = $null
        $errors = $null
        $ast = [Management.Automation.Language.Parser]::ParseFile(
            $Path, [ref]$tokens, [ref]$errors
        )
        @($errors).Count | Should -Be 0
        $definition = $ast.Find({
                param($node)
                $node -is [Management.Automation.Language.FunctionDefinitionAst] -and
                $node.Name -eq $Name
            }, $true)
        $definition | Should -Not -BeNullOrEmpty
        Set-Item -Path "Function:\global:$Name" -Value $definition.Body.GetScriptBlock()
    }

    $script:taskbarScript = Resolve-Path (Join-Path $PSScriptRoot `
            '..\playbook\Executables\AtlasModules\Scripts\Internal\Set-TaskbarPins.ps1')
    $script:startScript = Resolve-Path (Join-Path $PSScriptRoot `
            '..\playbook\Executables\AtlasModules\Scripts\Internal\Set-StartLayout.ps1')
    $script:newUserScript = Resolve-Path (Join-Path $PSScriptRoot `
            '..\playbook\Executables\AtlasModules\Scripts\Initialize-NewUser.ps1')
    Import-FunctionUnderTest -Path $script:taskbarScript -Name Resolve-AtlasTaskbarBrowser
    Import-FunctionUnderTest -Path $script:taskbarScript -Name Invoke-AtlasTaskbarRegistryWrite
    Import-FunctionUnderTest -Path $script:startScript -Name Test-AtlasStartPinPolicySupported
}

AfterAll {
    Remove-Item Function:\Resolve-AtlasTaskbarBrowser -ErrorAction SilentlyContinue
    Remove-Item Function:\Invoke-AtlasTaskbarRegistryWrite -ErrorAction SilentlyContinue
    Remove-Item Function:\Test-AtlasStartPinPolicySupported -ErrorAction SilentlyContinue
}

Describe 'Taskbar pin fallback' {
    BeforeEach {
        $script:shortcutTable = @{
            'Selected'       = @{ Path = 'C:\Selected\browser.exe' }
            'Microsoft Edge' = @{ Path = 'C:\Edge\msedge.exe' }
            'File Explorer'  = @{ Path = 'C:\Windows\explorer.exe' }
        }
    }

    It 'keeps an installed selected browser' {
        Mock Test-Path { $LiteralPath -eq 'C:\Selected\browser.exe' }

        Resolve-AtlasTaskbarBrowser -RequestedBrowser Selected `
            -ShortcutTable $script:shortcutTable -EdgeName 'Microsoft Edge' `
            -ExplorerName 'File Explorer' | Should -BeExactly 'Selected'
    }

    It 'warns and falls back to Edge when the selected browser is missing' {
        Mock Test-Path { $LiteralPath -eq 'C:\Edge\msedge.exe' }

        $warnings = @()
        $result = Resolve-AtlasTaskbarBrowser -RequestedBrowser Selected `
            -ShortcutTable $script:shortcutTable -EdgeName 'Microsoft Edge' `
            -ExplorerName 'File Explorer' -WarningVariable warnings

        $result | Should -BeExactly 'Microsoft Edge'
        @($warnings).Count | Should -Be 1
        [string]$warnings[0] | Should -Match 'Selected.*not installed'
    }

    It 'warns and falls back to File Explorer when no browser is installed' {
        Mock Test-Path { $false }

        $warnings = @()
        $result = Resolve-AtlasTaskbarBrowser -RequestedBrowser Selected `
            -ShortcutTable $script:shortcutTable -EdgeName 'Microsoft Edge' `
            -ExplorerName 'File Explorer' -WarningVariable warnings

        $result | Should -BeExactly 'File Explorer'
        @($warnings).Count | Should -Be 2
    }
}

Describe 'Taskbar registry writes' {
    It 'turns a native reg.exe failure into a terminating error' {
        $fakeReg = Join-Path $TestDrive 'reg-failure.cmd'
        Set-Content -LiteralPath $fakeReg -Value '@exit /b 5'

        {
            Invoke-AtlasTaskbarRegistryWrite -RegExe $fakeReg -RegistryKey 'HKCU\Test' `
                -Name Favorites -Data '00'
        } | Should -Throw '*exit code 5*'
    }

    It 'uses System32 reg.exe and guarantees temporary-directory cleanup' {
        $source = Get-Content -LiteralPath $script:taskbarScript -Raw
        $source | Should -Match "ChildPath 'System32\\reg\.exe'"
        $source | Should -Match 'finally\s*\{[\s\S]*Remove-Item -LiteralPath \$tmp\.FullName'
    }

    It 'stamps the canonical Explorer AppUserModelID onto the generated pin' {
        $source = Get-Content -LiteralPath $script:taskbarScript -Raw

        $source | Should -Match `
            "-AppUserModelId 'Microsoft\.Windows\.Explorer'"
    }
}

Describe 'Installing-user shell completion' {
    It 'explicitly imports every module used directly by new-user setup' {
        $source = Get-Content -LiteralPath $script:newUserScript -Raw

        foreach ($moduleName in @('Atlas.Shortcuts', 'Atlas.Themes', 'Atlas.Toggles')) {
            $source | Should -Match ([regex]::Escape("'$moduleName'"))
        }
        $source | Should -Match 'Import-Module -Name \$moduleManifest -Force -ErrorAction Stop'
    }

    It 'creates the current user Atlas desktop shortcut with the Atlas folder icon' {
        $source = Get-Content -LiteralPath $script:newUserScript -Raw

        $source | Should -Match "GetFolderPath\('DesktopDirectory'\)"
        $source | Should -Match 'Join-Path \$desktopPath ''Atlas\.lnk'''
        $source | Should -Match 'Join-Path \$atlasModules ''Other\\atlas-folder\.ico'''
        $source | Should -Match 'New-AtlasShortcut -Source \$atlasDesktop'
    }

    It 'refreshes the installing user Explorer session after committing shell state' {
        $source = Get-Content -LiteralPath $script:newUserScript -Raw
        $fromInstallCompletion = [regex]::Match(
            $source,
            'if \(\$FromInstall\) \{\s*Set-SetupMarker -Value 2(?<body>[\s\S]*?)\s*return\s*\}'
        )

        $fromInstallCompletion.Success | Should -BeTrue
        $fromInstallCompletion.Groups['body'].Value |
            Should -Match 'Invoke-CurrentSessionExplorerRefresh'
    }

    It 'runs safe exact-user OneDrive cleanup for later non-install accounts' {
        $source = Get-Content -LiteralPath $script:newUserScript -Raw
        $nonInstallStart = $source.IndexOf('if (-not $FromInstall) {',
            $source.IndexOf('& $initializer'))
        $setupStageStart = $source.IndexOf('if ($setupMarker -lt 1)', $nonInstallStart)
        $nonInstallSource = $source.Substring(
            $nonInstallStart,
            $setupStageStart - $nonInstallStart
        )

        $nonInstallSource | Should -Match 'Remove-OneDriveCurrentUserData\.ps1'
        $nonInstallSource | Should -Match '-ExpectedUserSid \$sid'
    }

    It 'removes the successful RunOnce retry before restarting Explorer' {
        $source = Get-Content -LiteralPath $script:newUserScript -Raw
        $completionMarker = $source.LastIndexOf('Set-SetupMarker -Value 2')
        $retryRemoval = $source.IndexOf('Remove-ItemProperty -Path $runOncePath',
            $completionMarker)
        $explorerRefresh = $source.IndexOf('Invoke-CurrentSessionExplorerRefresh',
            $completionMarker)

        $completionMarker | Should -BeGreaterThan -1
        $retryRemoval | Should -BeGreaterThan $completionMarker
        $explorerRefresh | Should -BeGreaterThan $retryRemoval
    }

    It 'logs only substantive setup stages and announces readiness after final refresh' {
        $source = Get-Content -LiteralPath $script:newUserScript -Raw
        $finalizerStart = $source.IndexOf('if ($FinalizeSearch) {')
        $finalizerEnd = $source.IndexOf('# Reinstalls deliberately', $finalizerStart)
        $finalizerSource = $source.Substring(
            $finalizerStart,
            $finalizerEnd - $finalizerStart
        )

        $source | Should -Match 'if \(-not \$FinalizeSearch\) \{[\s\S]*Start-Transcript'
        $finalizerSource | Should -Match `
            'Invoke-CurrentSessionExplorerRefresh[\s\S]*Your account is ready to use\.'
        @([regex]::Matches($source, 'Your account is ready to use\.')).Count |
            Should -Be 1
    }
}

Describe 'Start pin policy support' {
    It 'requires the servicing revision that introduced the 24H2 GPO' {
        Test-AtlasStartPinPolicySupported -Build 26100 -Revision 4769 | Should -BeFalse
        Test-AtlasStartPinPolicySupported -Build 26100 -Revision 4770 | Should -BeTrue
        Test-AtlasStartPinPolicySupported -Build 26100 -Revision 9000 | Should -BeTrue
    }

    It 'accepts later Windows build families' {
        Test-AtlasStartPinPolicySupported -Build 26200 -Revision 1 | Should -BeTrue
    }

    It 'provides a clear prerequisite diagnostic' {
        $source = Get-Content -LiteralPath $script:startScript -Raw
        $source | Should -Match 'KB5062660'
        $source | Should -Match '26100\.4770'
    }
}
