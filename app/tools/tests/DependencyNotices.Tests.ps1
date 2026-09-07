# Run with PowerShell 7; fixtures never use the real Cargo cache or dependency files.
Describe 'Dependency notice release gate' {
BeforeAll {
    $script:exporter = Join-Path $PSScriptRoot '../Export-DependencyNotices.ps1'
}
AfterAll { Remove-Item Function:script:cargo -ErrorAction SilentlyContinue }
BeforeEach {
    $script:fixture = Join-Path $TestDrive ([guid]::NewGuid().ToString('N'))
    $package = Join-Path $fixture 'package'
    New-Item -ItemType Directory -Force "$fixture/licenses", "$package/nested" | Out-Null
    Set-Content "$fixture/Cargo.lock" 'fixture lock'
    Set-Content "$fixture/licenses/supplements.json" '[]'
    Set-Content "$package/LICENSE" ('Permission and copyright fixture. ' * 4)
    Set-Content "$package/nested/LICENSE-other" ('Additional bundled code notice. ' * 4)
    $metadata = @{ packages = @(@{ name = 'fixture'; version = '1.0.0'; manifest_path = "$package/Cargo.toml"; source = 'registry+fixture'; license = 'MIT'; repository = 'https://example.invalid/fixture' }) } | ConvertTo-Json -Depth 5
    # Capture fixture data lexically: the exporter runs in a child script scope.
    $cargoStub = {
        if ($args[0] -eq 'metadata') { return $metadata }
        return 'fixture v1.0.0'
    }.GetNewClosure()
    Set-Item Function:script:cargo -Value $cargoStub
    $script:LASTEXITCODE = 0
}
    It 'collects nested notices and reproduces the checked output' {
        & $exporter -AppDirectory $fixture
        { & $exporter -AppDirectory $fixture -Check } | Should -Not -Throw
        $inventory = Get-Content "$fixture/licenses/dependency-inventory.json" -Raw | ConvertFrom-Json
        $inventory.packages[0].notices.Count | Should -Be 2
        $inventory.packages[0].normalWindowsDependency | Should -BeTrue
    }
    It 'rejects a stale generated distribution notice' {
        & $exporter -AppDirectory $fixture
        Add-Content "$fixture/licenses/THIRD-PARTY-NOTICES.txt" 'altered'
        { & $exporter -AppDirectory $fixture -Check } | Should -Throw '*Stale dependency notices*'
    }
    It 'retains short copyright notices rather than using a length heuristic' {
        Set-Content "$fixture/package/NOTICE" 'Copyright 2026 Example Authors.'
        & $exporter -AppDirectory $fixture
        $text = Get-Content "$fixture/licenses/THIRD-PARTY-NOTICES.txt" -Raw
        $text | Should -Match 'Copyright 2026 Example Authors\.'
        $inventory = Get-Content "$fixture/licenses/dependency-inventory.json" -Raw | ConvertFrom-Json
        $inventory.packages[0].notices.Count | Should -Be 3
    }
    It 'does not accept a flattened license symlink as license text' {
        Remove-Item "$fixture/package/nested/LICENSE-other"
        Set-Content "$fixture/package/LICENSE" '../LICENSE-MIT'
        & $exporter -AppDirectory $fixture -WarningAction SilentlyContinue
        { & $exporter -AppDirectory $fixture -Check } | Should -Throw '*Unresolved notices*'
    }
    It 'rejects a supplemental notice with a modified hash' {
        Set-Content "$fixture/licenses/supplement.txt" ('Fixture notice ' * 10)
        @(@{ package = 'fixture'; version = '1.0.0'; file = 'supplement.txt'; url = 'https://example.invalid/0123456789012345678901234567890123456789/LICENSE'; sha256 = 'INVALID' }) | ConvertTo-Json | Set-Content "$fixture/licenses/supplements.json"
        { & $exporter -AppDirectory $fixture } | Should -Throw '*Supplement hash mismatch*'
    }
}
