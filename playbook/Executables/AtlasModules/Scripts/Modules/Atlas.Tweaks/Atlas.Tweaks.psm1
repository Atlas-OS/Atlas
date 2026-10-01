# Atlas.Tweaks - declarative tweak engine module.
Set-StrictMode -Version 3.0

# No -Force: a nested forced import unloads the caller's copy in Windows PowerShell 5.1.
foreach ($dependencyManifest in @(
    '..\Atlas.Core\Atlas.Core.psd1'
    '..\Atlas.Registry\Atlas.Registry.psd1'
    '..\Atlas.Services\Atlas.Services.psd1'
    '..\Atlas.TasksProcs\Atlas.TasksProcs.psd1'
    '..\Atlas.Toggles\Atlas.Toggles.psd1'
)) {
    $manifestPath = Join-Path -Path $PSScriptRoot -ChildPath $dependencyManifest
    if (-not (Test-Path -LiteralPath $manifestPath -PathType Leaf)) {
        throw "Required Atlas.Tweaks dependency '$manifestPath' is missing."
    }
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
    'Manifest.ps1'
    'Applicability.ps1'
    'Invoke.ps1'
    'Schema.ps1'
    'Verify.ps1'
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
    'Test-AtlasTweakSchema',
    'Test-AtlasTweak', 'Test-AtlasTweakCategory'
)
