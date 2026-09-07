# Atlas.Toggles - user-facing toggle engine.
Set-StrictMode -Version 3.0

# Atlas.Core supplies context, logging and privilege checks; Registry, Services and
# TasksProcs apply a state's declarative entries; Atlas.State mirrors recorded choices
# into the machine state document. Import each by its exact manifest and reuse instances
# a long-running caller already owns: a nested forced import would unload their global
# command surface in Windows PowerShell 5.1.
foreach ($dependencyManifest in @(
    '..\Atlas.Core\Atlas.Core.psd1'
    '..\Atlas.Registry\Atlas.Registry.psd1'
    '..\Atlas.Services\Atlas.Services.psd1'
    '..\Atlas.TasksProcs\Atlas.TasksProcs.psd1'
    '..\Atlas.State\Atlas.State.psd1'
)) {
    $manifestPath = Join-Path -Path $PSScriptRoot -ChildPath $dependencyManifest
    if (-not (Test-Path -LiteralPath $manifestPath -PathType Leaf)) {
        throw "Required Atlas.Toggles dependency '$manifestPath' is missing."
    }
    Import-Module -Name $manifestPath -ErrorAction Stop
}

$domainRoot = Join-Path -Path $PSScriptRoot -ChildPath 'Domain'

foreach ($domainModule in @(
    'State.ps1'
    'Interaction.ps1'
    'Native.ps1'
    'Definition.ps1'
    'Engine.ps1'
    'Reapply.ps1'
    'Verify.ps1'
)) {
    $domainPath = Join-Path -Path $domainRoot -ChildPath $domainModule
    if (-not (Test-Path -LiteralPath $domainPath -PathType Leaf)) {
        throw "Required Atlas.Toggles domain module '$domainPath' is missing."
    }

    . $domainPath
}

Export-ModuleMember -Function @(
    'Get-AtlasToggleDefinition', 'Test-AtlasToggleDefinition', 'Get-AtlasToggleStateWork',
    'Invoke-AtlasToggle', 'Invoke-AtlasToggleMachineState',
    'Get-AtlasToggleState', 'Get-AtlasToggleStateRecords', 'Set-AtlasToggleState',
    'Invoke-AtlasToggleNativeCommand',
    'Initialize-AtlasToggleStateStore',
    'Invoke-AtlasToggleReapply', 'Invoke-AtlasToggleUserReapply',
    'Test-AtlasToggleState', 'Test-AtlasToggleDrift'
)
