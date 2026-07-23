# Atlas.Toggles - user-facing toggle engine.
Set-StrictMode -Version 3.0

$domainRoot = Join-Path -Path $PSScriptRoot -ChildPath 'Domain'

foreach ($domainModule in @(
    'State.ps1'
    'Interaction.ps1'
    'Native.ps1'
    'Engine.ps1'
    'Reapply.ps1'
)) {
    $domainPath = Join-Path -Path $domainRoot -ChildPath $domainModule
    if (-not (Test-Path -LiteralPath $domainPath -PathType Leaf)) {
        throw "Required Atlas.Toggles domain module '$domainPath' is missing."
    }

    . $domainPath
}

Export-ModuleMember -Function @(
    'Get-AtlasToggleDefinition', 'Invoke-AtlasToggle',
    'Invoke-AtlasToggleMachineDependency',
    'Get-AtlasToggleState', 'Set-AtlasToggleState',
    'Invoke-AtlasToggleNativeCommand',
    'Initialize-AtlasToggleStateStore',
    'Invoke-AtlasToggleReapply', 'Invoke-AtlasToggleUserReapply'
)
