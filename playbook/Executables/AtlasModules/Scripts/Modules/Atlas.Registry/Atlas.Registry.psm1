# Atlas.Registry - registry engine module.
Set-StrictMode -Version 3.0

# Atlas.Core supplies logging, install context and token evidence for path binding.
$coreManifest = Join-Path -Path $PSScriptRoot -ChildPath '..\Atlas.Core\Atlas.Core.psd1'
if (-not (Test-Path -LiteralPath $coreManifest -PathType Leaf)) {
    throw "Required Atlas.Core manifest '$coreManifest' is missing."
}
# Reuse the orchestrator's Core instance; forcing it from nested module scope
# removes global Core commands from the caller in Windows PowerShell 5.1.
Import-Module -Name $coreManifest -ErrorAction Stop

$domainRoot = Join-Path -Path $PSScriptRoot -ChildPath 'Domain'

foreach ($domainModule in @(
    'Paths.ps1'
    'Values.ps1'
    'Keys.ps1'
    'RegFile.ps1'
    'Entries.ps1'
    'UserPaths.ps1'
)) {
    $domainPath = Join-Path -Path $domainRoot -ChildPath $domainModule
    if (-not (Test-Path -LiteralPath $domainPath -PathType Leaf)) {
        throw "Required Atlas.Registry domain module '$domainPath' is missing."
    }

    . $domainPath
}

Export-ModuleMember -Function @(
    'Resolve-AtlasRegistryPath', 'Initialize-AtlasRegistryIdentityContext',
    'Set-AtlasRegistryValue', 'Remove-AtlasRegistryValue', 'New-AtlasRegistryKey', 'Remove-AtlasRegistryKey',
    'Import-AtlasRegFile', 'Invoke-AtlasRegistryEntries',
    'Test-AtlasArchMatch', 'Get-AtlasRegistryEntryTargetScope',
    'Get-UserPath'
)
