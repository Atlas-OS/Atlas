# Atlas.Services - service and driver configuration module.
Set-StrictMode -Version 3.0

# Atlas.Core supplies Write-AtlasLog/Get-AtlasContext. Import it explicitly so that
# standalone entry points (setSvc.cmd, Internal\Set-ServiceStartup.ps1) work without
# initPowerShell.ps1 having populated PSModulePath first.
if (-not (Get-Command -Name 'Write-AtlasLog' -ErrorAction SilentlyContinue)) {
    Import-Module -Name (Join-Path -Path $PSScriptRoot -ChildPath '..\Atlas.Core\Atlas.Core.psd1')
}

$domainRoot = Join-Path -Path $PSScriptRoot -ChildPath 'Domain'

foreach ($domainModule in @(
    'Startup.ps1'
    'Backup.ps1'
)) {
    $domainPath = Join-Path -Path $domainRoot -ChildPath $domainModule
    if (-not (Test-Path -LiteralPath $domainPath -PathType Leaf)) {
        throw "Required Atlas.Services domain module '$domainPath' is missing."
    }

    . $domainPath
}

Export-ModuleMember -Function @(
    'Set-AtlasServiceStartup', 'Stop-AtlasService', 'Export-AtlasServicesBackup'
)
