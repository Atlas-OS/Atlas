BeforeAll {
    . (Join-Path $PSScriptRoot 'AtlasTestHost.ps1')
    $script:HealthToggleManifest = Join-Path $script:AtlasTestModulesRoot 'Atlas.Toggles\Atlas.Toggles.psd1'
    Import-Module $script:HealthToggleManifest -Force
    $script:HealthModule = Get-Module Atlas.Toggles
    $script:HealthCompanion = Join-Path $script:AtlasTestRepoRoot 'playbook\Executables\AtlasModules\Toggles\Troubleshooting\AtlasHealth.ps1'
    $script:HealthScripts = Join-Path $TestDrive 'Health scripts with spaces'
    New-Item (Join-Path $script:HealthScripts 'Entry') -ItemType Directory -Force | Out-Null
    $script:HealthEntry = Join-Path $script:HealthScripts 'Entry\Test-AtlasHealth.ps1'
}

Describe 'Atlas health launcher process' {
    BeforeEach {
        Mock -ModuleName Atlas.Toggles Wait-AtlasExit {}
        Mock -ModuleName Atlas.Toggles Write-Host {}
    }

    It 'displays a report with exit code <Code> despite reloading the calling module' -ForEach @(
        @{ Code = 0 }
        @{ Code = 1 }
    ) {
        # The entry script reloads Atlas.Toggles, the module running this companion.
        # Exit code 1 reports drift, so it is displayed rather than treated as an error.
        $fixture = @'
function Get-AtlasHealthReport { 'Health fixture report' }
Import-Module -Name '__MANIFEST__' -Force
Get-AtlasHealthReport
exit __CODE__
'@
        $fixture.Replace('__MANIFEST__', $script:HealthToggleManifest.Replace("'", "''")).
            Replace('__CODE__', [string]$Code) | Set-Content $script:HealthEntry -Encoding UTF8
        $context = [pscustomobject]@{
            ScriptsPath = $script:HealthScripts
            WinDir = [Environment]::GetFolderPath('Windows')
        }
        & $script:HealthModule {
            param($Companion, $Context)
            . $Companion
            Show-AtlasHealthReport -Toggle $Context
        } $script:HealthCompanion $context
        Should -Invoke -ModuleName Atlas.Toggles Write-Host -Times 1 -Exactly -ParameterFilter {
            $Object -eq 'Health fixture report'
        }
        # The toggle engine owns the final interactive pause.
        Should -Invoke -ModuleName Atlas.Toggles Wait-AtlasExit -Times 0 -Exactly
    }

    It 'preserves a failed check and its diagnostic instead of displaying success' {
        "[Console]::Error.WriteLine('Health fixture failure'); exit 2" |
            Set-Content $script:HealthEntry -Encoding UTF8
        $context = [pscustomobject]@{
            ScriptsPath = $script:HealthScripts
            WinDir = [Environment]::GetFolderPath('Windows')
        }
        {
            & $script:HealthModule {
                param($Companion, $Context)
                . $Companion
                Show-AtlasHealthReport -Toggle $Context
            } $script:HealthCompanion $context
        } | Should -Throw '*disallowed code 2*Health fixture failure*'
        Should -Invoke -ModuleName Atlas.Toggles Wait-AtlasExit -Times 0 -Exactly
    }
}
