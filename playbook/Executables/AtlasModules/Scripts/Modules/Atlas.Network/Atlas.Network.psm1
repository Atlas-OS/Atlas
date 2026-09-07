# Atlas.Network - network adapter defaults and File Sharing configuration module.
Set-StrictMode -Version 3.0

# Atlas.Core supplies logging, privilege checks and checked native launches; Atlas.Registry
# writes the Sharing context-menu and NcdAutoSetup values; Atlas.Services sets the NetBT
# driver start value; Atlas.Toggles applies the Network Discovery machine state that File
# Sharing depends on. Reuse instances a long-running caller already owns: a nested forced
# import would unload their global command surface in Windows PowerShell 5.1.
foreach ($dependencyManifest in @(
    '..\Atlas.Core\Atlas.Core.psd1'
    '..\Atlas.Registry\Atlas.Registry.psd1'
    '..\Atlas.Services\Atlas.Services.psd1'
    '..\Atlas.Toggles\Atlas.Toggles.psd1'
)) {
    $manifestPath = Join-Path -Path $PSScriptRoot -ChildPath $dependencyManifest
    if (-not (Test-Path -LiteralPath $manifestPath -PathType Leaf)) {
        throw "Required Atlas.Network dependency '$manifestPath' is missing."
    }
    Import-Module -Name $manifestPath -ErrorAction Stop
}

$domainRoot = Join-Path -Path $PSScriptRoot -ChildPath 'Domain'

foreach ($domainModule in @(
    'Defaults.ps1'
    'FileSharing.ps1'
)) {
    $domainPath = Join-Path -Path $domainRoot -ChildPath $domainModule
    if (-not (Test-Path -LiteralPath $domainPath -PathType Leaf)) {
        throw "Required Atlas.Network domain module '$domainPath' is missing."
    }

    . $domainPath
}

Export-ModuleMember -Function @(
    'Set-AtlasNetworkDefaults', 'Enable-AtlasFileSharing', 'Disable-AtlasFileSharing'
)
