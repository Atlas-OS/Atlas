# Atlas.Appx - AppX support module.
Set-StrictMode -Version 3.0

# No -Force: a nested forced import unloads the caller's copy in Windows PowerShell 5.1.
foreach ($dependencyManifest in @(
    '..\Atlas.Core\Atlas.Core.psd1'
    '..\Atlas.Download\Atlas.Download.psd1'
)) {
    $manifestPath = Join-Path -Path $PSScriptRoot -ChildPath $dependencyManifest
    if (-not (Test-Path -LiteralPath $manifestPath -PathType Leaf)) {
        throw "Required Atlas.Appx dependency '$manifestPath' is missing."
    }
    Import-Module -Name $manifestPath -ErrorAction Stop
}

$domainRoot = Join-Path -Path $PSScriptRoot -ChildPath 'Domain'

foreach ($domainModule in @(
    'Snapshot.ps1'
    'Removal.ps1'
    'Cache.ps1'
    'PhoneLink.ps1'
    'GameBar.ps1'
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
    'Remove-AtlasPhoneLinkAppx',
    'Install-AtlasGameBar'
)
