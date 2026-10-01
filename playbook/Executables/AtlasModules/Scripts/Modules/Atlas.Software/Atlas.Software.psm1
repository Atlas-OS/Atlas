# Atlas.Software - software management module.
Set-StrictMode -Version 3.0

# No -Force: a nested forced import unloads the caller's copy in Windows PowerShell 5.1.
foreach ($dependencyManifest in @(
    '..\Atlas.Core\Atlas.Core.psd1'
    '..\Atlas.Shortcuts\Atlas.Shortcuts.psd1'
    '..\Atlas.Download\Atlas.Download.psd1'
)) {
    $manifestPath = Join-Path -Path $PSScriptRoot -ChildPath $dependencyManifest
    if (-not (Test-Path -LiteralPath $manifestPath -PathType Leaf)) {
        throw "Required Atlas.Software dependency '$manifestPath' is missing."
    }
    Import-Module -Name $manifestPath -ErrorAction Stop
}

$domainRoot = Join-Path -Path $PSScriptRoot -ChildPath 'Domain'

foreach ($domainModule in @(
    'CbsPackages.ps1'
    'Installers.ps1'
    'NanaZipStore.ps1'
    'SoftwarePicker.ps1'
    'OneDrive.ps1'
)) {
    $domainPath = Join-Path -Path $domainRoot -ChildPath $domainModule
    if (-not (Test-Path -LiteralPath $domainPath -PathType Leaf)) {
        throw "Required Atlas.Software domain module '$domainPath' is missing."
    }

    . $domainPath
}

Export-ModuleMember -Function @(
    'Install-AtlasCbsPackage', 'Uninstall-AtlasCbsPackage',
    'Install-AtlasSoftware', 'Show-AtlasSoftwarePicker', 'Remove-AtlasOneDrive'
)
