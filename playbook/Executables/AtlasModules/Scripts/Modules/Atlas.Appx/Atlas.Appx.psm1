# Atlas.Appx - AppX support module.
Set-StrictMode -Version 3.0

# Atlas.Core supplies logging, context and option lookup for the AppX helpers.
$coreManifest = Join-Path -Path $PSScriptRoot -ChildPath '..\Atlas.Core\Atlas.Core.psd1'
if (-not (Test-Path -LiteralPath $coreManifest -PathType Leaf)) {
    throw "Required Atlas.Core manifest '$coreManifest' is missing."
}
# Reuse the orchestrator's Core instance; forcing it from nested module scope
# removes global Core commands from the caller in Windows PowerShell 5.1.
Import-Module -Name $coreManifest -ErrorAction Stop

$domainRoot = Join-Path -Path $PSScriptRoot -ChildPath 'Domain'

foreach ($domainModule in @(
    'Snapshot.ps1'
    'Removal.ps1'
    'Cache.ps1'
    'PhoneLink.ps1'
)) {
    $domainPath = Join-Path -Path $domainRoot -ChildPath $domainModule
    if (-not (Test-Path -LiteralPath $domainPath -PathType Leaf)) {
        throw "Required Atlas.Appx domain module '$domainPath' is missing."
    }

    . $domainPath
}

Export-ModuleMember -Function @(
    'Save-AtlasAppxSnapshot', 'Set-AtlasAppxDeprovisioned',
    'Get-AtlasAppxRemovalDefinition', 'Invoke-AtlasAppxRemovalPlan',
    'Clear-AtlasAppxCache', 'Invoke-AtlasUserAppxCacheCleanup',
    'Remove-AtlasPhoneLinkAppx'
)
