# Atlas.Services - service and driver configuration module.
Set-StrictMode -Version 3.0

# Atlas.Core supplies logging and install context for the service helpers.
$coreManifest = Join-Path -Path $PSScriptRoot -ChildPath '..\Atlas.Core\Atlas.Core.psd1'
if (-not (Test-Path -LiteralPath $coreManifest -PathType Leaf)) {
    throw "Required Atlas.Core manifest '$coreManifest' is missing."
}
# Reuse the orchestrator's Core instance; forcing it from nested module scope
# removes global Core commands from the caller in Windows PowerShell 5.1.
Import-Module -Name $coreManifest -ErrorAction Stop

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
    'Set-AtlasServiceStartup', 'Stop-AtlasService',
    'Restore-AtlasServicesBackup', 'Export-AtlasServicesBackup'
)
