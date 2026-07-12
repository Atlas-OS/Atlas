BeforeAll {
    $script:RepoRoot = (Resolve-Path (Join-Path $PSScriptRoot '..')).ProviderPath
    $script:PlaybookRoot = Join-Path $script:RepoRoot 'playbook'
    $script:ModulesRoot = Join-Path $script:PlaybookRoot `
        'Executables\AtlasModules\Scripts\Modules'
    $script:TweaksRoot = Join-Path $script:PlaybookRoot `
        'Executables\AtlasModules\Scripts\Tweaks'
    $script:ConfigurationRoot = Join-Path $script:PlaybookRoot 'Configuration'

    Import-Module -Name (Join-Path $script:ModulesRoot `
            'Atlas.Tweaks\Atlas.Tweaks.psd1') -Force

    [xml]$playbook = [IO.File]::ReadAllText((Join-Path $script:PlaybookRoot 'playbook.conf'))
    $script:FeatureOptions = @($playbook.SelectNodes(
            '/Playbook/FeaturePages/*/Options/*/Name'
        ) | ForEach-Object { $_.InnerText } | Sort-Object -Unique)

    . (Join-Path $script:RepoRoot 'tools\build\AtlasBuild\AtlasYamlAction.ps1')
    $script:CustomActions = @(Get-AtlasYamlAction `
            -Path (Join-Path $script:ConfigurationRoot 'custom.yml') `
            -RelativePath 'custom.yml')
}

Describe 'Atlas option handoff contract' {
    It 'keeps FeaturePage, state, YAML, and tweak option sets identical' {
        $recordActions = @($script:CustomActions | Where-Object {
                $_.Type -ceq 'run' -and
                [string]$_.Properties.args -match `
                    ' -Operation RecordOption -Option (?<Option>[a-z0-9-]+)$'
            })
        $yamlOptions = foreach ($action in $recordActions) {
            $match = [regex]::Match(
                [string]$action.Properties.args,
                ' -Operation RecordOption -Option (?<Option>[a-z0-9-]+)$'
            )
            $name = $match.Groups['Option'].Value
            [string]$action.Properties.option | Should -BeExactly $name
            $name
        }

        $statePath = Join-Path $script:PlaybookRoot `
            'Executables\AtlasModules\Scripts\Initialize-AtlasInstallState.ps1'
        $tokens = $null
        $parseErrors = $null
        $stateAst = [Management.Automation.Language.Parser]::ParseFile(
            $statePath,
            [ref]$tokens,
            [ref]$parseErrors
        )
        $parseErrors | Should -BeNullOrEmpty
        $optionParameter = @($stateAst.ParamBlock.Parameters | Where-Object {
                $_.Name.VariablePath.UserPath -ceq 'Option'
            })
        $optionParameter.Count | Should -Be 1
        $optionValidateSet = @($optionParameter[0].Attributes | Where-Object {
                $_.TypeName.FullName -ceq 'ValidateSet'
            })
        $optionValidateSet.Count | Should -Be 1
        $stateOptions = @($optionValidateSet[0].PositionalArguments | ForEach-Object {
                [string]$_.SafeGetValue()
            } | Sort-Object -Unique)

        $tweakOptions = @(InModuleScope Atlas.Tweaks {
                $script:AtlasKnownOptions
            } | Sort-Object -Unique)

        @($yamlOptions | Sort-Object -Unique) | Should -Be $script:FeatureOptions
        $recordActions.Count | Should -Be $script:FeatureOptions.Count
        $stateOptions | Should -Be $script:FeatureOptions
        $tweakOptions | Should -Be $script:FeatureOptions
    }

    It 'uses only declared FeaturePage options in tweak data and option checks' {
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
        Get-ChildItem -LiteralPath $script:PlaybookRoot `
            -Include '*.ps1','*.psm1' -File -Recurse |
            Select-String -Pattern $literalCallPattern -AllMatches |
            ForEach-Object {
                foreach ($match in $_.Matches) {
                    $referencedOptions.Add($match.Groups[1].Value)
                }
            }

        $unknown = @($referencedOptions | Sort-Object -Unique |
            Where-Object { $script:FeatureOptions -notcontains $_ })
        $unknown | Should -BeNullOrEmpty
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
