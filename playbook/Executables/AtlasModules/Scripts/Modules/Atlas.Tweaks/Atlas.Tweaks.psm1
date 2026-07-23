# Atlas.Tweaks - declarative tweak engine module.
Set-StrictMode -Version 3.0

# Atlas.Core supplies shared runtime helpers; Atlas.Registry applies Registry entries
# and classifies entry scopes; Atlas.Services applies checked service startup changes;
# Atlas.TasksProcs applies scheduled-task changes with missing-task tolerance.
foreach ($dependencyManifest in @(
    '..\Atlas.Core\Atlas.Core.psd1'
    '..\Atlas.Registry\Atlas.Registry.psd1'
    '..\Atlas.Services\Atlas.Services.psd1'
    '..\Atlas.TasksProcs\Atlas.TasksProcs.psd1'
)) {
    $manifestPath = Join-Path -Path $PSScriptRoot -ChildPath $dependencyManifest
    if (-not (Test-Path -LiteralPath $manifestPath -PathType Leaf)) {
        throw "Required Atlas.Tweaks dependency '$manifestPath' is missing."
    }
    # Reuse dependencies already owned by the long-running install orchestrator.
    # A nested forced import unloads their global command surface in Windows PowerShell.
    Import-Module -Name $manifestPath -ErrorAction Stop
}

$script:AtlasTweakPostUserRegistryRefreshOperations = @(
    'ShellRefresh'
    'ExplorerRefresh'
    'SearchShellRefresh'
    'StartMenuRefresh'
    'ExplorerAndSettingsRefresh'
)

$domainRoot = Join-Path -Path $PSScriptRoot -ChildPath 'Domain'

foreach ($domainModule in @(
    'DataFile.ps1'
    'Manifest.ps1'
    'Applicability.ps1'
    'Invoke.ps1'
    'Schema.ps1'
)) {
    $domainPath = Join-Path -Path $domainRoot -ChildPath $domainModule
    if (-not (Test-Path -LiteralPath $domainPath -PathType Leaf)) {
        throw "Required Atlas.Tweaks domain module '$domainPath' is missing."
    }

    . $domainPath
}

Export-ModuleMember -Function @(
    'Get-AtlasTweakManifest', 'Test-AtlasTweakManifest', 'Test-AtlasTweakApplicable',
    'Get-AtlasTweakCategoryPostUserRegistryRefresh',
    'Invoke-AtlasTweak', 'Invoke-AtlasTweakCategory',
    'Test-AtlasTweakSchema'
)
