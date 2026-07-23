BeforeAll {
    $repoRoot = (Resolve-Path (Join-Path $PSScriptRoot '..')).Path
    $script:seedPath = Join-Path $repoRoot 'playbook\Executables\DEFAULT.reg'
    $script:togglesRoot = Join-Path $repoRoot 'playbook\Executables\AtlasModules\Toggles'

    # The seed ships as UTF-16LE with a BOM; Import-AtlasDefaultRegistry.ps1 hands it
    # directly to reg.exe.
    $seedBytes = [IO.File]::ReadAllBytes($script:seedPath)
    $seedBytes[0..1] | Should -Be @(0xFF, 0xFE)
    $seedText = [Text.Encoding]::Unicode.GetString($seedBytes, 2, $seedBytes.Length - 2)

    $script:seedToggleNames = @(
        foreach ($match in [regex]::Matches($seedText,
                '(?m)^\[HKEY_LOCAL_MACHINE\\SOFTWARE\\AtlasOS\\Services\\([^\]]+)\]\s*$')) {
            $match.Groups[1].Value
        }
    )

    $script:toggleDefinitionNames = @(
        Get-ChildItem -LiteralPath $script:togglesRoot -Recurse -Filter '*.ps1' -File |
            ForEach-Object { $_.BaseName }
    )
}

Describe 'DEFAULT.reg toggle state seed' {
    It 'seeds at least one toggle state' {
        $script:seedToggleNames.Count | Should -BeGreaterThan 0
    }

    It 'seeds only direct child keys of AtlasOS\Services' {
        foreach ($name in $script:seedToggleNames) {
            $name | Should -Not -Match '\\'
        }
    }

    It 'seeds each toggle state at most once' {
        $duplicates = @($script:seedToggleNames | Group-Object |
                Where-Object { $_.Count -gt 1 } | ForEach-Object { $_.Name })
        $duplicates | Should -BeNullOrEmpty
    }

    It 'seeds states only for toggles that have a definition script' {
        # Not every toggle persists a state (one-shot actions have no seed), so the seed
        # must be a subset of the definitions; an unmatched seed key is dead state or a
        # renamed toggle whose seed was not updated.
        $script:toggleDefinitionNames.Count | Should -BeGreaterThan 0
        foreach ($name in $script:seedToggleNames) {
            $script:toggleDefinitionNames | Should -Contain $name `
                -Because "seed key 'Services\$name' must match a toggle definition under AtlasModules\Toggles"
        }
    }
}
