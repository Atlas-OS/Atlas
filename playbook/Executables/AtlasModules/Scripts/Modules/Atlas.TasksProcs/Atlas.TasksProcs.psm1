# Atlas.TasksProcs - scheduled task and process helper module.
Set-StrictMode -Version 3.0

# Atlas.Core supplies Write-AtlasLog. Import the adjacent module so standalone
# callers do not depend on PSModulePath or an ambient command with the same name.
$coreManifestPath = Join-Path $PSScriptRoot '..\Atlas.Core\Atlas.Core.psd1'
if (-not [IO.File]::Exists($coreManifestPath)) {
    throw "Required Atlas.Core manifest is missing: '$coreManifestPath'."
}
# Reuse the orchestrator's Core instance; forcing it from nested module scope
# removes global Core commands from the caller in Windows PowerShell 5.1.
Import-Module -Name $coreManifestPath -ErrorAction Stop

$domainRoot = Join-Path -Path $PSScriptRoot -ChildPath 'Domain'

foreach ($domainModule in @(
    'ScheduledTasks.ps1'
    'Processes.ps1'
)) {
    $domainPath = Join-Path -Path $domainRoot -ChildPath $domainModule
    if (-not [IO.File]::Exists($domainPath)) {
        throw "Required Atlas.TasksProcs domain module '$domainPath' is missing."
    }

    . $domainPath
}

Export-ModuleMember -Function @(
    'Disable-AtlasScheduledTask', 'Enable-AtlasScheduledTask', 'Remove-AtlasScheduledTask',
    'Stop-AtlasProcess', 'Wait-AtlasExplorerShellRecovery',
    'Stop-AtlasProcessUnderRoot', 'Stop-AtlasScheduledTaskUnderRoot'
)
