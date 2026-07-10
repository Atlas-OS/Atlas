BeforeAll {
    $script:repoRoot = Split-Path -Parent $PSScriptRoot
    $script:helperPath = Join-Path $script:repoRoot 'playbook\Executables\AtlasModules\Scripts\Internal\OpenShell-ThemeTransaction.ps1'
    $script:downloadIntegrityPath = Join-Path $script:repoRoot 'playbook\Executables\AtlasModules\Scripts\Internal\Download-Integrity.ps1'
    $script:installerPath = Join-Path $script:repoRoot 'playbook\Executables\AtlasModules\Scripts\Internal\Install-OpenShellTheme.ps1'
    $script:packageInstallerPath = Join-Path $script:repoRoot 'playbook\Executables\AtlasModules\Scripts\Internal\Install-OpenShellPackage.ps1'
    $script:entryPath = Join-Path $script:repoRoot 'playbook\Executables\AtlasModules\Scripts\Install-OpenShell.ps1'
    $script:launcherPath = Join-Path $script:repoRoot 'playbook\Executables\AtlasDesktop\4. Interface Tweaks\Start Menu\Install Open-Shell.cmd'
    . $script:downloadIntegrityPath
    . $script:helperPath
}

Describe 'Open-Shell theme transaction' {
    BeforeEach {
        Mock Test-AtlasProtectedExecutionAcl { $true }
        $caseRoot = Join-Path $TestDrive ([guid]::NewGuid().ToString('N'))
        $script:sourceDirectory = Join-Path $caseRoot 'source'
        $script:skinsDirectory = Join-Path $caseRoot 'skins'
        [void](New-Item -ItemType Directory -Path $script:sourceDirectory -Force)
        [void](New-Item -ItemType Directory -Path $script:skinsDirectory -Force)

        $script:expectedFiles = @()
        foreach ($definition in @(
                [pscustomobject]@{ Name = 'Theme.skin'; Bytes = [byte[]](1, 2, 3, 4) }
                [pscustomobject]@{ Name = 'Tiles.xml'; Bytes = [byte[]](5, 6, 7) }
            )) {
            $path = Join-Path $script:sourceDirectory $definition.Name
            [IO.File]::WriteAllBytes($path, $definition.Bytes)
            $script:expectedFiles += [pscustomobject]@{
                Name = $definition.Name
                Length = $definition.Bytes.Length
                Sha256 = Get-AtlasOpenShellThemeFileSha256 -Path $path
            }
        }
    }

    It 'publishes an exact first install and leaves no transaction artifacts' {
        Invoke-AtlasOpenShellThemeFileTransaction `
            -SourceDirectory $sourceDirectory `
            -SkinsDirectory $skinsDirectory `
            -ExpectedFiles $expectedFiles

        [IO.File]::ReadAllBytes((Join-Path $skinsDirectory 'Theme.skin')) |
            Should -Be ([byte[]](1, 2, 3, 4))
        [IO.File]::ReadAllBytes((Join-Path $skinsDirectory 'Tiles.xml')) |
            Should -Be ([byte[]](5, 6, 7))
        @(Get-ChildItem -LiteralPath $skinsDirectory -Force -Filter '*.atlas-*').Count |
            Should -Be 0
    }

    It 'reapplies over existing files idempotently and removes protected backups' {
        [IO.File]::WriteAllBytes(
            (Join-Path $skinsDirectory 'Theme.skin'),
            [byte[]](9, 9, 9)
        )
        [IO.File]::WriteAllBytes(
            (Join-Path $skinsDirectory 'Tiles.xml'),
            [byte[]](8, 8)
        )

        Invoke-AtlasOpenShellThemeFileTransaction `
            -SourceDirectory $sourceDirectory `
            -SkinsDirectory $skinsDirectory `
            -ExpectedFiles $expectedFiles

        (Get-AtlasOpenShellThemeFileSha256 -Path (Join-Path $skinsDirectory 'Theme.skin')) |
            Should -BeExactly $expectedFiles[0].Sha256
        (Get-AtlasOpenShellThemeFileSha256 -Path (Join-Path $skinsDirectory 'Tiles.xml')) |
            Should -BeExactly $expectedFiles[1].Sha256
        @(Get-ChildItem -LiteralPath $skinsDirectory -Force -Filter '*.atlas-*').Count |
            Should -Be 0
    }

    It 'converges valid candidate and rollback artifacts left by interrupted publication' {
        $themeTarget = Join-Path $skinsDirectory 'Theme.skin'
        $themeCandidate = "$themeTarget.atlas-candidate"
        [IO.File]::WriteAllBytes($themeTarget, [byte[]](9, 9, 9))
        [IO.File]::Copy((Join-Path $sourceDirectory 'Theme.skin'), $themeCandidate)

        $tilesTarget = Join-Path $skinsDirectory 'Tiles.xml'
        $tilesRollback = "$tilesTarget.atlas-rollback"
        [IO.File]::WriteAllBytes($tilesRollback, [byte[]](8, 8, 8))

        Invoke-AtlasOpenShellThemeFileTransaction `
            -SourceDirectory $sourceDirectory `
            -SkinsDirectory $skinsDirectory `
            -ExpectedFiles $expectedFiles

        (Get-AtlasOpenShellThemeFileSha256 -Path $themeTarget) |
            Should -BeExactly $expectedFiles[0].Sha256
        (Get-AtlasOpenShellThemeFileSha256 -Path $tilesTarget) |
            Should -BeExactly $expectedFiles[1].Sha256
        @(Get-ChildItem -LiteralPath $skinsDirectory -Force -Filter '*.atlas-*').Count |
            Should -Be 0
    }

    It 'retains an unknown candidate and the prior target without publishing it' {
        $target = Join-Path $skinsDirectory 'Theme.skin'
        $candidate = "$target.atlas-candidate"
        $priorBytes = [byte[]](9, 8, 7)
        [IO.File]::WriteAllBytes($target, $priorBytes)
        [IO.File]::WriteAllBytes($candidate, [byte[]](0, 1))

        {
            Invoke-AtlasOpenShellThemeFileTransaction `
                -SourceDirectory $sourceDirectory `
                -SkinsDirectory $skinsDirectory `
                -ExpectedFiles $expectedFiles
        } | Should -Throw '*failed its normal-file or length check*'

        [IO.File]::ReadAllBytes($target) | Should -Be $priorBytes
        [IO.File]::ReadAllBytes($candidate) | Should -Be ([byte[]](0, 1))
    }

    It 'retains an ambiguous target and rollback artifact for explicit recovery' {
        $target = Join-Path $skinsDirectory 'Theme.skin'
        $rollback = "$target.atlas-rollback"
        $targetBytes = [byte[]](9, 8, 7)
        $rollbackBytes = [byte[]](6, 5, 4)
        [IO.File]::WriteAllBytes($target, $targetBytes)
        [IO.File]::WriteAllBytes($rollback, $rollbackBytes)

        {
            Invoke-AtlasOpenShellThemeFileTransaction `
                -SourceDirectory $sourceDirectory `
                -SkinsDirectory $skinsDirectory `
                -ExpectedFiles $expectedFiles
        } | Should -Throw '*target and rollback artifact*ambiguous*'

        [IO.File]::ReadAllBytes($target) | Should -Be $targetBytes
        [IO.File]::ReadAllBytes($rollback) | Should -Be $rollbackBytes
    }

    It 'rejects an existing target that an untrusted principal can mutate' {
        [IO.File]::WriteAllBytes(
            (Join-Path $skinsDirectory 'Theme.skin'),
            [byte[]](9, 9, 9)
        )
        Mock Test-AtlasProtectedExecutionAcl { $false }

        {
            Invoke-AtlasOpenShellThemeFileTransaction `
                -SourceDirectory $sourceDirectory `
                -SkinsDirectory $skinsDirectory `
                -ExpectedFiles $expectedFiles
        } | Should -Throw '*untrusted owner or writable principal*'
    }

    It 'rolls an earlier publication back when a later target is invalid' {
        $originalBytes = [byte[]](9, 8, 7, 6)
        [IO.File]::WriteAllBytes(
            (Join-Path $skinsDirectory 'Theme.skin'),
            $originalBytes
        )
        [void](New-Item -ItemType Directory -Path (Join-Path $skinsDirectory 'Tiles.xml'))

        {
            Invoke-AtlasOpenShellThemeFileTransaction `
                -SourceDirectory $sourceDirectory `
                -SkinsDirectory $skinsDirectory `
                -ExpectedFiles $expectedFiles
        } | Should -Throw '*failed and was rolled back*'

        [IO.File]::ReadAllBytes((Join-Path $skinsDirectory 'Theme.skin')) |
            Should -Be $originalBytes
        (Test-Path -LiteralPath (Join-Path $skinsDirectory 'Tiles.xml') -PathType Container) |
            Should -BeTrue
        @(Get-ChildItem -LiteralPath $skinsDirectory -Force -Filter '*.atlas-*').Count |
            Should -Be 0
    }

    It 'rejects an unexpected extracted entry before publishing anything' {
        [IO.File]::WriteAllBytes(
            (Join-Path $sourceDirectory 'unexpected.bin'),
            [byte[]](1)
        )

        {
            Invoke-AtlasOpenShellThemeFileTransaction `
                -SourceDirectory $sourceDirectory `
                -SkinsDirectory $skinsDirectory `
                -ExpectedFiles $expectedFiles
        } | Should -Throw '*unexpected number of entries*'

        @(Get-ChildItem -LiteralPath $skinsDirectory -Force).Count | Should -Be 0
    }

    It 'accepts the protected Program Files ACL and rejects a user-owned destination' {
        {
            Assert-AtlasOpenShellThemeDirectory `
                -Path ([Environment]::GetFolderPath(
                    [Environment+SpecialFolder]::ProgramFiles
                )) `
                -Description 'Program Files'
        } | Should -Not -Throw

        {
            Assert-AtlasOpenShellThemeDirectory `
                -Path $skinsDirectory `
                -Description 'test skins'
        } | Should -Throw '*untrusted owner*'
    }

    It 'pins the reviewed inner manifest and exposes theme-only partial success' {
        $installer = Get-Content -LiteralPath $installerPath -Raw
        $packageInstaller = Get-Content -LiteralPath $packageInstallerPath -Raw
        $entry = Get-Content -LiteralPath $entryPath -Raw
        $launcher = Get-Content -LiteralPath $launcherPath -Raw
        $transaction = Get-Content -LiteralPath $helperPath -Raw

        $installer | Should -Match 'OpenShell-ThemeTransaction\.ps1'
        $installer | Should -Match 'd6fd55cec15b9936978557781b5e3f2e46dac5d26269b785bf97c8730412e205'
        $installer | Should -Match '7c6d7f878f0a8b43da09b04575000b30abb9a25515aaf1551c2c7c7e6046f706'
        $installer | Should -Match '32c4818d3fc5f080cfd289cf2190d2244c7b4bb033330be1675867abfc4feacb'
        $installer | Should -Match 'Invoke-AtlasOpenShellThemeFileTransaction'
        $packageInstaller | Should -Match '5749469[\s\S]+?e3f7f41fe718d01a80f2af7f8d6f6c50aded56e1ea80f85d83eab03ac0cdd493'
        $packageInstaller | Should -Match '6072899[\s\S]+?65b80580c2d130af88c17c2482235984bb96994595f2da2da3b77f62b6ffbbe6'
        $packageInstaller | Should -Match 'Get-FileHash -LiteralPath \$msiPath -Algorithm SHA256'
        $packageInstaller | Should -Match '\$startMenuPath = [\s\S]+?StartMenu\.exe[\s\S]+?\$resolvedStartMenu = Resolve-AtlasProtectedExecutionPath[\s\S]+?-Path \$startMenuPath'
        $packageInstaller | Should -Match '\$installedVersion\.ToString\(3\) -ne \$openShellVersion'
        $packageInstaller | Should -Match 'RebootRequired = \$processExitCode -eq 3010'
        $transaction | Should -Match '\[IO\.File\]::Replace\(\$candidatePath, \$targetPath, \$rollbackPath\)'
        $transaction | Should -Match '\$stream\.Flush\(\$true\)'
        $transaction | Should -Not -Match '\.atlas-old-'
        $entry | Should -Match 'theme failed transactionally[\s\S]+?exit 3'
        $entry | Should -Match '\$packageResult\.RebootRequired[\s\S]+?exit 3010'
        $launcher | Should -Match '(?ms)^\s*if errorlevel 0 \(\r?\n\s*if errorlevel 1 exit /b\r?\n\s*\) else \(\r?\n\s*exit /b 1\r?\n\s*\)'
    }
}
