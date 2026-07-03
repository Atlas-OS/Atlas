# Atlas.Appx - AppX support module.
Set-StrictMode -Version 3.0

# Atlas.Core supplies Write-AtlasLog/Get-AtlasContext. Import it explicitly so the
# Tasks forwarder scripts work without initPowerShell.ps1 having populated PSModulePath.
if (-not (Get-Command -Name 'Write-AtlasLog' -ErrorAction SilentlyContinue)) {
    Import-Module -Name (Join-Path -Path $PSScriptRoot -ChildPath '..\Atlas.Core\Atlas.Core.psd1')
}

$domainRoot = Join-Path -Path $PSScriptRoot -ChildPath 'Domain'

foreach ($domainModule in @(
    'Snapshot.ps1'
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
    'Clear-AtlasAppxCache', 'Remove-AtlasPhoneLinkAppx'
)
