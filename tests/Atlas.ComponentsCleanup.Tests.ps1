BeforeAll {
    $script:atlasScriptsRoot = Join-Path -Path $PSScriptRoot `
        -ChildPath '..\playbook\Executables\AtlasModules\Scripts'
    $script:componentsPhase = Join-Path -Path $script:atlasScriptsRoot `
        -ChildPath 'Phases\Invoke-ComponentsPhase.ps1'
    $script:oneDriveUserCleanup = Join-Path -Path $script:atlasScriptsRoot `
        -ChildPath 'Internal\Remove-OneDriveCurrentUserData.ps1'
}

Describe 'Components phase deferred and exact-user cleanup contracts' {
    It 'writes the MDCoreSvc state before deleting its retry task' {
        $source = Get-Content -LiteralPath $script:componentsPhase -Raw
        $commandStart = $source.IndexOf('$mdCoreArgs =')
        $commandEnd = $source.IndexOf('$mdCoreTask =', $commandStart)
        $commandSource = $source.Substring($commandStart, $commandEnd - $commandStart)

        $commandSource | Should -Match 'reg add'
        $commandSource | Should -Match '&&'
        $commandSource.IndexOf('reg add') | Should -BeLessThan `
            $commandSource.IndexOf('schtasks /delete')
    }

    It 'dispatches OneDrive profile cleanup through the exact-user launcher' {
        $source = Get-Content -LiteralPath $script:componentsPhase -Raw

        $source | Should -Match ([regex]::Escape('Remove-OneDriveCurrentUserData.ps1'))
        $source | Should -Match 'Invoke-AtlasAsUser'
        $source | Should -Match ([regex]::Escape("'-ExpectedUserSid'"))
        $source | Should -Match 'Exact-user OneDrive leftover cleanup exited with code'
        $source | Should -Not -Match 'throw "Exact-user OneDrive cleanup failed'
    }

    It 'rethrows unconfirmed OneDrive process containment instead of logging and continuing' {
        $source = Get-Content -LiteralPath $script:componentsPhase -Raw
        $oneDriveStart = $source.IndexOf("Remove-AtlasOneDrive`r`n")
        if ($oneDriveStart -lt 0) {
            $oneDriveStart = $source.IndexOf("Remove-AtlasOneDrive`n")
        }
        $warning = $source.IndexOf('Removing OneDrive failed:', $oneDriveStart)
        $catchSource = $source.Substring($oneDriveStart, $warning - $oneDriveStart)

        $catchSource | Should -Match 'AtlasProcessMayStillBeRunning'
        $catchSource | Should -Match 'if \(\$containmentUnconfirmed\)[\s\S]+throw'
    }
}

Describe 'OneDrive exact-user cleanup boundary' {
    It 'parses in Windows PowerShell syntax' {
        $tokens = $null
        $errors = $null
        [Management.Automation.Language.Parser]::ParseFile(
            $script:oneDriveUserCleanup,
            [ref]$tokens,
            [ref]$errors
        ) | Out-Null

        $errors | Should -BeNullOrEmpty
    }

    It 'uses only the current-user registry provider and never enumerates HKEY_USERS' {
        $source = Get-Content -LiteralPath $script:oneDriveUserCleanup -Raw

        $source | Should -Not -Match 'HKEY_USERS|HKU:'
        $source | Should -Match ([regex]::Escape('HKCU:\SOFTWARE'))
        $source | Should -Match 'actualSid[\s\S]+expectedSid'
        $source | Should -Match 'refuses to run from an elevated token'
    }

    It 'validates identity and every cleanup root before its first mutation' {
        $source = Get-Content -LiteralPath $script:oneDriveUserCleanup -Raw
        $firstMutation = $source.IndexOf('Microsoft.PowerShell.Management\Remove-Item ')

        $source.IndexOf('$actualSid =') | Should -BeLessThan $firstMutation
        $source.IndexOf('$oneDriveCache =') | Should -BeLessThan $firstMutation
        $source.IndexOf('$oneDriveShortcut =') | Should -BeLessThan $firstMutation
        $source.IndexOf('$oneDriveFolder =') | Should -BeLessThan $firstMutation
    }

    It 'treats missing optional User Shell Folder values as absent' {
        $source = Get-Content -LiteralPath $script:oneDriveUserCleanup -Raw

        $source | Should -Not -Match 'Get-ItemPropertyValue'
        $source | Should -Match '\.GetValue\(\s*\$entry\.Name,\s*\$null,'
        $source | Should -Match 'DoNotExpandEnvironmentNames'
        $source | Should -Match '\$shellFolderKey\.Dispose\(\)'
    }
}
