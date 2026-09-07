# Atlas.Privacy - location, telemetry-log and telemetry-component configuration module.
Set-StrictMode -Version 3.0

# Atlas.Core supplies logging, install context and privilege checks; Atlas.Registry
# writes the Find My Device policy; Atlas.Services sets the location service start
# values. Reuse instances a long-running caller already owns: a nested forced import
# would unload their global command surface in Windows PowerShell 5.1.
foreach ($dependencyManifest in @(
    '..\Atlas.Core\Atlas.Core.psd1'
    '..\Atlas.Registry\Atlas.Registry.psd1'
    '..\Atlas.Services\Atlas.Services.psd1'
)) {
    $manifestPath = Join-Path -Path $PSScriptRoot -ChildPath $dependencyManifest
    if (-not (Test-Path -LiteralPath $manifestPath -PathType Leaf)) {
        throw "Required Atlas.Privacy dependency '$manifestPath' is missing."
    }
    Import-Module -Name $manifestPath -ErrorAction Stop
}

$domainRoot = Join-Path -Path $PSScriptRoot -ChildPath 'Domain'

foreach ($domainModule in @(
    'Location.ps1'
    'Telemetry.ps1'
)) {
    $domainPath = Join-Path -Path $domainRoot -ChildPath $domainModule
    if (-not (Test-Path -LiteralPath $domainPath -PathType Leaf)) {
        throw "Required Atlas.Privacy domain module '$domainPath' is missing."
    }

    . $domainPath
}

Export-ModuleMember -Function @(
    'Set-AtlasLocationMachineState', 'Clear-AtlasTelemetryLogFiles', 'Remove-AtlasTelemetryComponents', 'Read-AtlasTelemetryPackageChoice', 'Set-AtlasTelemetryPackageState'
)
