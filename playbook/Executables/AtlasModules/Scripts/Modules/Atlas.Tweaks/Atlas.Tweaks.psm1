# Atlas.Tweaks - declarative tweak engine module.
Set-StrictMode -Version 3.0

$domainRoot = Join-Path -Path $PSScriptRoot -ChildPath 'Domain'

foreach ($domainModule in @(
    'DataFile.ps1'
    'Manifest.ps1'
    'Applicability.ps1'
    'Invoke.ps1'
    'Schema.ps1'
)) {
    $domainPath = Join-Path -Path $domainRoot -ChildPath $domainModule
    if (-not (Test-Path -LiteralPath $domainPath -PathType Leaf)) {
        throw "Required Atlas.Tweaks domain module '$domainPath' is missing."
    }

    . $domainPath
}

Export-ModuleMember -Function @(
    'Get-AtlasTweakManifest', 'Test-AtlasTweakManifest', 'Test-AtlasTweakApplicable',
    'Invoke-AtlasTweak', 'Invoke-AtlasTweakCategory',
    'Test-AtlasTweakSchema'
)
