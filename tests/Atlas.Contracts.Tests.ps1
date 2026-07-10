BeforeAll {
    $script:RepoRoot = (Resolve-Path (Join-Path $PSScriptRoot '..')).ProviderPath
    $script:PlaybookRoot = Join-Path $script:RepoRoot 'playbook'
    $script:ModulesRoot = Join-Path $script:PlaybookRoot 'Executables\AtlasModules\Scripts\Modules'
    $script:TweaksRoot = Join-Path $script:PlaybookRoot 'Executables\AtlasModules\Scripts\Tweaks'
    $script:ConfigurationRoot = Join-Path $script:PlaybookRoot 'Configuration'

    Import-Module -Name (Join-Path $script:ModulesRoot 'Atlas.Tweaks\Atlas.Tweaks.psd1') -Force

    $playbookConf = [xml](Get-Content -LiteralPath (Join-Path $script:PlaybookRoot 'playbook.conf') -Raw)
    $script:FeatureOptions = @($playbookConf.SelectNodes('/Playbook/FeaturePages/*/Options/*/Name') |
        ForEach-Object { $_.InnerText } |
        Sort-Object -Unique)

    $script:CustomYaml = Get-Content -LiteralPath (Join-Path $script:ConfigurationRoot 'custom.yml') -Raw
}

Describe 'AME option handoff contract' {
    It 'keeps FeaturePage options, YAML flag writers, and YAML option gates identical' {
        $flagOptions = @([regex]::Matches($script:CustomYaml, 'Flags\\option-([a-z0-9-]+)\.flag') |
            ForEach-Object { $_.Groups[1].Value } |
            Sort-Object -Unique)
        $gatedOptions = @([regex]::Matches($script:CustomYaml, "option:\s*'([a-z0-9-]+)'") |
            ForEach-Object { $_.Groups[1].Value } |
            Sort-Object -Unique)

        $flagOptions | Should -Be $script:FeatureOptions
        $gatedOptions | Should -Be $script:FeatureOptions
    }

    It 'keeps the tweak schema option allow-list identical to FeaturePage options' {
        $schemaOptions = @(InModuleScope Atlas.Tweaks { $script:AtlasKnownOptions } | Sort-Object -Unique)
        $schemaOptions | Should -Be $script:FeatureOptions
    }

    It 'uses only declared FeaturePage options in tweak data and Test-AtlasOption calls' {
        $referencedOptions = [System.Collections.Generic.List[string]]::new()

        Get-ChildItem -LiteralPath $script:TweaksRoot -Filter '*.psd1' -File -Recurse |
            Where-Object { $_.Name -ne 'tweaks.manifest.psd1' } |
            ForEach-Object {
                $definition = Import-PowerShellDataFile -LiteralPath $_.FullName
                if ($definition.ContainsKey('Option')) {
                    $referencedOptions.Add([string]$definition.Option)
                }
            }

        $literalCallPattern = 'Test-AtlasOption\s+-Name\s+[''"]([^''"]+)[''"]'
        Get-ChildItem -LiteralPath $script:PlaybookRoot -Include '*.ps1','*.psm1' -File -Recurse |
            Select-String -Pattern $literalCallPattern -AllMatches |
            ForEach-Object {
                foreach ($match in $_.Matches) {
                    $referencedOptions.Add($match.Groups[1].Value)
                }
            }

        $unknownOptions = @($referencedOptions | Sort-Object -Unique |
            Where-Object { $script:FeatureOptions -notcontains $_ })
        $unknownOptions | Should -BeNullOrEmpty
    }
}

Describe 'AME install phase handoff contract' {
    BeforeAll {
        $script:ConfigurationFiles = @(Get-ChildItem -LiteralPath $script:ConfigurationRoot -Filter '*.yml' -File -Recurse)
        $script:ConfigurationText = ($script:ConfigurationFiles | ForEach-Object {
                Get-Content -LiteralPath $_.FullName -Raw
            }) -join "`n"
        $script:PhaseRoot = Join-Path $script:PlaybookRoot 'Executables\AtlasModules\Scripts\Phases'
    }

    It 'invokes every shipped phase and references no phase without an implementation' {
        $invokedPhases = @([regex]::Matches($script:ConfigurationText, 'Invoke-AtlasInstall\.ps1.*?-Phase\s+([A-Za-z]+)') |
            ForEach-Object { $_.Groups[1].Value } |
            Sort-Object -Unique)
        $implementedPhases = @(Get-ChildItem -LiteralPath $script:PhaseRoot -Filter 'Invoke-*Phase.ps1' -File |
            ForEach-Object { $_.BaseName -replace '^Invoke-', '' -replace 'Phase$', '' } |
            Sort-Object -Unique)

        $invokedPhases | Should -Be $implementedPhases
    }

    It 'halts AME when every Invoke-AtlasInstall call returns nonzero' {
        foreach ($configurationFile in $script:ConfigurationFiles) {
            $lines = @(Get-Content -LiteralPath $configurationFile.FullName)
            for ($index = 0; $index -lt $lines.Count; $index++) {
                if ($lines[$index] -notmatch 'Invoke-AtlasInstall\.ps1') {
                    continue
                }

                $endIndex = [Math]::Min($index + 5, $lines.Count - 1)
                $actionBlock = $lines[$index..$endIndex] -join "`n"
                $actionBlock | Should -Match 'handleExitCodes:\s*\{\s*"!0":\s*halt\s*\}' `
                    -Because "$($configurationFile.Name):$($index + 1) invokes an install phase"
            }
        }
    }
}

Describe 'Payload module import contracts' {
    BeforeDiscovery {
        $modulesRoot = Join-Path (Resolve-Path (Join-Path $PSScriptRoot '..\playbook')).ProviderPath 'Executables\AtlasModules\Scripts\Modules'
        $script:PayloadManifests = @(Get-ChildItem -LiteralPath $modulesRoot -Filter 'Atlas.*.psd1' -File -Recurse |
            ForEach-Object { @{ Name = $_.BaseName; FullName = $_.FullName; ModulesRoot = $modulesRoot } })
    }

    BeforeAll {
        $script:ImportHarness = Join-Path $TestDrive 'Test-AtlasModuleImport.ps1'
        @'
param(
    [Parameter(Mandatory = $true)][string]$ManifestPath,
    [Parameter(Mandatory = $true)][string]$ModulesRoot
)

$ErrorActionPreference = 'Stop'
$manifest = Import-PowerShellDataFile -LiteralPath $ManifestPath
$expectedExports = @($manifest.FunctionsToExport)
$moduleName = [IO.Path]::GetFileNameWithoutExtension($ManifestPath)
$env:PSModulePath = "$ModulesRoot$([IO.Path]::PathSeparator)$env:PSModulePath"

# Load PowerShell's platform modules explicitly, then disable autoloading. Atlas-to-Atlas
# dependencies must resolve from RequiredModules/the explicit module root after this point.
Import-Module Microsoft.PowerShell.Management -ErrorAction Stop
Import-Module Microsoft.PowerShell.Utility -ErrorAction Stop
$null = Get-Command Import-Module,Get-Command
$PSModuleAutoloadingPreference = 'None'
Import-Module -Name $ManifestPath -Force -ErrorAction Stop
$actualExports = @((Get-Command -Module $moduleName -CommandType Function).Name)

$missing = @($expectedExports | Where-Object { $actualExports -notcontains $_ })
$unexpected = @($actualExports | Where-Object { $expectedExports -notcontains $_ })
if ($missing.Count -gt 0 -or $unexpected.Count -gt 0) {
    throw "Export mismatch. Missing: $($missing -join ', '); unexpected: $($unexpected -join ', ')."
}
'@ | Set-Content -LiteralPath $script:ImportHarness -Encoding UTF8

        $script:CurrentPowerShell = if ($PSVersionTable.PSEdition -eq 'Desktop') {
            Join-Path $PSHOME 'powershell.exe'
        }
        else {
            Join-Path $PSHOME 'pwsh.exe'
        }
    }

    It '<Name> imports in a clean process with autoloading disabled and exact exports' -ForEach $PayloadManifests {
        $output = & $script:CurrentPowerShell -NoProfile -ExecutionPolicy Bypass -File $script:ImportHarness `
            -ManifestPath $FullName -ModulesRoot $ModulesRoot 2>&1

        $LASTEXITCODE | Should -Be 0 -Because ($output -join "`n")
    }
}
