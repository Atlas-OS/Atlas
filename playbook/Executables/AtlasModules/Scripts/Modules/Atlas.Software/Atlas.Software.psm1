# Atlas.Software - software management module.
Set-StrictMode -Version 3.0

# Atlas.Core supplies Write-AtlasLog/Get-AtlasContext/Assert-AtlasPrivilege and the UI
# helpers (Read-Pause, Read-MessageBox); Atlas.Shortcuts supplies New-Shortcut. Import
# them explicitly so standalone entry points (packageInstall.ps1, the software picker)
# work without initPowerShell.ps1 having populated PSModulePath first.
if (-not (Get-Command -Name 'Write-AtlasLog' -ErrorAction SilentlyContinue)) {
    Import-Module -Name (Join-Path -Path $PSScriptRoot -ChildPath '..\Atlas.Core\Atlas.Core.psd1')
}
if (-not (Get-Command -Name 'New-Shortcut' -ErrorAction SilentlyContinue)) {
    Import-Module -Name (Join-Path -Path $PSScriptRoot -ChildPath '..\Atlas.Shortcuts\Atlas.Shortcuts.psd1')
}

$domainRoot = Join-Path -Path $PSScriptRoot -ChildPath 'Domain'

foreach ($domainModule in @(
    'CbsPackages.ps1'
    'Installers.ps1'
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
