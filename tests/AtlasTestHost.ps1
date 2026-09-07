# Shared test-host setup. Every payload test file dot-sources this at the top of its
# BeforeAll so tests run the way the payload runs: under Windows PowerShell 5.1, with
# module resolution pinned to the inbox module root, the payload module tree and the
# module root that provides Pester. This mirrors Scripts\Initialize-AtlasPowerShell.ps1
# and keeps every test file free of host-specific setup.
#
# Usage inside a test file:
#     BeforeAll { . (Join-Path $PSScriptRoot 'AtlasTestHost.ps1') }

if ($PSVersionTable.PSEdition -ne 'Desktop') {
    throw "Payload tests run under Windows PowerShell 5.1; this host is PowerShell $($PSVersionTable.PSVersion) ($($PSVersionTable.PSEdition))."
}

$script:AtlasTestRepoRoot = (Resolve-Path (Join-Path $PSScriptRoot '..')).ProviderPath
$script:AtlasTestScriptsRoot = Join-Path $script:AtlasTestRepoRoot 'playbook\Executables\AtlasModules\Scripts'
$script:AtlasTestModulesRoot = Join-Path $script:AtlasTestScriptsRoot 'Modules'
$script:AtlasTestToolsHost = (Get-Command -Name pwsh -CommandType Application -ErrorAction Stop | Select-Object -First 1).Source

$inboxModuleRoot = [IO.Path]::GetFullPath([IO.Path]::Combine($PSHOME, 'Modules'))
$pesterRoot = Split-Path -Parent (Split-Path -Parent (Get-Module -Name Pester).Path)
$env:PSModulePath = @($inboxModuleRoot, $script:AtlasTestModulesRoot, $pesterRoot) -join [IO.Path]::PathSeparator

foreach ($moduleName in @(
        'Microsoft.PowerShell.Management'
        'Microsoft.PowerShell.Utility'
        'Microsoft.PowerShell.Security'
    )) {
    Import-Module -Name ([IO.Path]::Combine($inboxModuleRoot, $moduleName, "$moduleName.psd1")) -ErrorAction Stop
}
