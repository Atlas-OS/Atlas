BeforeAll {
    . (Join-Path $PSScriptRoot 'AtlasTestHost.ps1')
    $script:repoRoot = $script:AtlasTestRepoRoot
    $script:ToolsHost = $script:AtlasTestToolsHost
    $script:CatalogTool = Join-Path $script:repoRoot 'tools\dev\Export-AtlasCatalog.ps1'
    $script:CatalogPath = Join-Path $script:repoRoot 'playbook\Executables\AtlasModules\Toggles\catalog.json'
    $script:TogglesRoot = Join-Path $script:repoRoot 'playbook\Executables\AtlasModules\Toggles'
}

Describe 'Tweak catalog routes' {
    BeforeEach {
        $script:fixtureRoot = Join-Path $TestDrive ([guid]::NewGuid().ToString('N'))
        $script:fixtureTweaks = Join-Path $script:fixtureRoot 'playbook\Executables\AtlasModules\Scripts\Tweaks'
        $toggleDirectory = Join-Path $script:fixtureRoot 'playbook\Executables\AtlasModules\Toggles\General'
        New-Item -ItemType Directory -Path $toggleDirectory -Force | Out-Null
        New-Item -ItemType Directory -Path (Join-Path $script:fixtureTweaks 'example') -Force | Out-Null
        "@{ Name = 'Fixture'; States = @(@{ Name = 'Disable'; StateValue = 0 }) }" |
            Set-Content -LiteralPath (Join-Path $toggleDirectory 'Fixture.psd1')
        @'
@{
    Categories = @(@{ Name = 'example'; ParentModes = @('Fresh'); Tweaks = @('category') })
    Standalone = @(@{ Slug = 'example/standalone'; ParentModes = @('Upgrade') })
    Disabled = @(@{ Slug = 'example/disabled'; Reason = 'Keep for comparison | not installed.' })
}
'@ | Set-Content -LiteralPath (Join-Path $script:fixtureTweaks 'tweaks.manifest.psd1')
        @'
@{
    Name = 'Category fixture'
    Option = 'fixture-option'
    Registry = @(@{ Path = 'HKCU\Software\AtlasFixture'; Name = 'Test'; Type = 'DWord'; Data = 0 })
    Script = 'category.ps1'
    PostUserRegistryRefresh = 'ExplorerRefresh'
}
'@ | Set-Content -LiteralPath (Join-Path $script:fixtureTweaks 'example\category.psd1')
        "@{ Name = 'Standalone fixture'; OnUpgrade = 'Only'; Script = 'standalone.ps1' }" |
            Set-Content -LiteralPath (Join-Path $script:fixtureTweaks 'example\standalone.psd1')
        "@{ Name = 'Disabled fixture' }" |
            Set-Content -LiteralPath (Join-Path $script:fixtureTweaks 'example\disabled.psd1')
        foreach ($name in 'category', 'standalone') {
            "throw 'Catalog generation must not execute companion scripts.'" |
                Set-Content -LiteralPath (Join-Path $script:fixtureTweaks "example\$name.ps1")
        }
        $script:fixtureDoc = Join-Path $script:fixtureRoot 'docs\catalog\tweaks.md'
    }

    It 'documents category gates, standalone work and disabled reasons without running companions' {
        $output = & $script:ToolsHost -NoProfile -File $script:CatalogTool -RepoRoot $script:fixtureRoot 2>&1
        $LASTEXITCODE | Should -Be 0 -Because ($output -join "`n")
        $markdown = [IO.File]::ReadAllText($script:fixtureDoc)
        $markdown | Should -Match 'Category tweaks: 1\. Standalone tweaks: 1\. Disabled definitions: 1\.'
        $markdown | Should -Match '## example\n\nInstall modes: Fresh\.'
        $markdown | Should -Match 'Option=fixture-option'
        $markdown | Should -Match 'registry 1, Script `category.ps1`, PostUserRegistryRefresh `ExplorerRefresh`'
        $markdown | Should -Match '## Standalone tweaks[\s\S]+`example/standalone`[\s\S]+ParentModes=Upgrade, OnUpgrade=Only[\s\S]+Script `standalone.ps1`'
        $markdown | Should -Match '## Disabled definitions[\s\S]+`example/disabled` \| Keep for comparison \\\| not installed\.'
        @($markdown -split "`n" | Where-Object { $_ -match '^\| `' }).Count | Should -Be 3

        $output = & $script:ToolsHost -NoProfile -File $script:CatalogTool -RepoRoot $script:fixtureRoot -Validate 2>&1
        $LASTEXITCODE | Should -Be 0 -Because ($output -join "`n")
    }

    It 'rejects a missing standalone definition before publishing any catalog output' {
        Remove-Item -LiteralPath (Join-Path $script:fixtureTweaks 'example\standalone.psd1')
        $output = & $script:ToolsHost -NoProfile -File $script:CatalogTool -RepoRoot $script:fixtureRoot 2>&1
        $LASTEXITCODE | Should -Be 1
        ($output -join "`n") | Should -Match "Manifest entry 'example/standalone' has no definition"
        $script:fixtureDoc | Should -Not -Exist
        Join-Path $script:fixtureRoot 'playbook\Executables\AtlasModules\Toggles\catalog.json' | Should -Not -Exist
    }
}

Describe 'Atlas catalog' {
    It 'is generated from the definitions with no drift' {
        $output = & $script:ToolsHost -NoProfile -ExecutionPolicy Bypass -File $script:CatalogTool -Validate 2>&1
        $LASTEXITCODE | Should -Be 0 -Because ($output -join "`n")
    }

    It 'lists every toggle definition exactly once with its states' {
        $catalog = Get-Content -LiteralPath $script:CatalogPath -Raw | ConvertFrom-Json
        $catalog.schemaVersion | Should -Be 1
        $definitions = @(Get-ChildItem -LiteralPath $script:TogglesRoot -Recurse -File -Filter '*.psd1')
        @($catalog.toggles).Count | Should -Be $definitions.Count
        @($catalog.toggles.name | Sort-Object -Unique).Count | Should -Be $definitions.Count
        foreach ($toggle in $catalog.toggles) {
            $toggle.group | Should -Not -BeNullOrEmpty
            $toggle.elevation | Should -BeIn @('None', 'Admin', 'TrustedInstaller')
            @($toggle.states).Count | Should -BeGreaterThan 0
        }
    }

    It 'ships the generated references beside the docs' {
        Join-Path $script:repoRoot 'docs\catalog\toggles.md' | Should -Exist
        Join-Path $script:repoRoot 'docs\catalog\tweaks.md' | Should -Exist
    }
    It 'keeps internal broker choices out of the public indexing states' {
        $catalog = Get-Content -LiteralPath $script:CatalogPath -Raw | ConvertFrom-Json
        $indexing = $catalog.toggles | Where-Object name -eq 'Indexing'
        @($indexing.states.name) | Should -Be @('Disable', 'Minimal', 'Enable')
    }
}
