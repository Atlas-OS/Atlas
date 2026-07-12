BeforeAll {
    $script:repoRoot = Split-Path -Parent $PSScriptRoot
    $script:helperPath = Join-Path $script:repoRoot 'playbook\Executables\AtlasModules\Scripts\Internal\OpenShell-ThemeTransaction.ps1'
    $script:downloadIntegrityPath = Join-Path $script:repoRoot 'playbook\Executables\AtlasModules\Scripts\Internal\Download-Integrity.ps1'
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

    It 'publishes exact files and is idempotent' {
        1..2 | ForEach-Object {
            Invoke-AtlasOpenShellThemeFileTransaction `
                -SourceDirectory $sourceDirectory `
                -SkinsDirectory $skinsDirectory `
                -ExpectedFiles $expectedFiles
        }

        [IO.File]::ReadAllBytes((Join-Path $skinsDirectory 'Theme.skin')) |
            Should -Be ([byte[]](1, 2, 3, 4))
        [IO.File]::ReadAllBytes((Join-Path $skinsDirectory 'Tiles.xml')) |
            Should -Be ([byte[]](5, 6, 7))
        @(Get-ChildItem -LiteralPath $skinsDirectory -Force -Filter '*.atlas-*').Count |
            Should -Be 0
    }

    It 'atomically replaces protected existing theme files' {
        [IO.File]::WriteAllBytes((Join-Path $skinsDirectory 'Theme.skin'), [byte[]](9, 9))
        [IO.File]::WriteAllBytes((Join-Path $skinsDirectory 'Tiles.xml'), [byte[]](8, 8))

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

    It 'does not overwrite an existing file with untrusted ownership' {
        $target = Join-Path $skinsDirectory 'Theme.skin'
        $priorBytes = [byte[]](9, 8, 7)
        [IO.File]::WriteAllBytes($target, $priorBytes)
        Mock Test-AtlasProtectedExecutionAcl { $false }

        {
            Invoke-AtlasOpenShellThemeFileTransaction `
                -SourceDirectory $sourceDirectory `
                -SkinsDirectory $skinsDirectory `
                -ExpectedFiles $expectedFiles
        } | Should -Throw '*untrusted owner or writable principal*'

        [IO.File]::ReadAllBytes($target) | Should -Be $priorBytes
        (Test-Path -LiteralPath (Join-Path $skinsDirectory 'Tiles.xml')) | Should -BeFalse
        @(Get-ChildItem -LiteralPath $skinsDirectory -Force -Filter '*.atlas-*').Count |
            Should -Be 0
    }

    It 'restores earlier files when a later target cannot be published' {
        $target = Join-Path $skinsDirectory 'Theme.skin'
        $priorBytes = [byte[]](9, 8, 7, 6)
        [IO.File]::WriteAllBytes($target, $priorBytes)
        [void](New-Item -ItemType Directory -Path (Join-Path $skinsDirectory 'Tiles.xml'))

        {
            Invoke-AtlasOpenShellThemeFileTransaction `
                -SourceDirectory $sourceDirectory `
                -SkinsDirectory $skinsDirectory `
                -ExpectedFiles $expectedFiles
        } | Should -Throw '*failed and was rolled back*'

        [IO.File]::ReadAllBytes($target) | Should -Be $priorBytes
        (Test-Path -LiteralPath (Join-Path $skinsDirectory 'Tiles.xml') -PathType Container) |
            Should -BeTrue
        @(Get-ChildItem -LiteralPath $skinsDirectory -Force -Filter '*.atlas-*').Count |
            Should -Be 0
    }

    It 'rejects unexpected extracted content before publishing anything' {
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
}
