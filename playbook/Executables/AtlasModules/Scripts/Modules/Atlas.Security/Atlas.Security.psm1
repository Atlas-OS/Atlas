# Atlas.Security - security configuration module.
Set-StrictMode -Version 3.0

# Atlas.Core supplies context, logging and privilege checks; Atlas.Registry writes the
# VBS runtime values. Import each by its exact manifest and reuse instances a
# long-running caller already owns: a nested forced import would unload their global
# command surface in Windows PowerShell 5.1.
foreach ($dependencyManifest in @(
    '..\Atlas.Core\Atlas.Core.psd1'
    '..\Atlas.Registry\Atlas.Registry.psd1'
)) {
    $manifestPath = Join-Path -Path $PSScriptRoot -ChildPath $dependencyManifest
    if (-not (Test-Path -LiteralPath $manifestPath -PathType Leaf)) {
        throw "Required Atlas.Security dependency '$manifestPath' is missing."
    }
    Import-Module -Name $manifestPath -ErrorAction Stop
}

$domainRoot = Join-Path -Path $PSScriptRoot -ChildPath 'Domain'

foreach ($domainModule in @(
    'Defender.ps1'
    'Vbs.ps1'
    'Permissions.ps1'
)) {
    $domainPath = Join-Path -Path $domainRoot -ChildPath $domainModule
    if (-not (Test-Path -LiteralPath $domainPath -PathType Leaf)) {
        throw "Required Atlas.Security domain module '$domainPath' is missing."
    }

    . $domainPath
}

Export-ModuleMember -Function @(
    'Get-AtlasDefenderState', 'Set-AtlasDefenderState', 'Read-AtlasDefenderStateChoice',
    'Get-AtlasVbsConfiguration', 'Set-AtlasVbsConfiguration',
    'Repair-AtlasWindowsTempPermissions'
)
