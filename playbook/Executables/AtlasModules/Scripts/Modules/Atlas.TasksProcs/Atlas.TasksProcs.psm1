# Atlas.TasksProcs - scheduled task and process helper module.
Set-StrictMode -Version 3.0

# Atlas.Core supplies Write-AtlasLog. Import it explicitly so standalone entry points
# work without initPowerShell.ps1 having populated PSModulePath first.
if (-not (Get-Command -Name 'Write-AtlasLog' -ErrorAction SilentlyContinue)) {
    Import-Module -Name (Join-Path -Path $PSScriptRoot -ChildPath '..\Atlas.Core\Atlas.Core.psd1')
}

$domainRoot = Join-Path -Path $PSScriptRoot -ChildPath 'Domain'

foreach ($domainModule in @(
    'ScheduledTasks.ps1'
    'Processes.ps1'
)) {
    $domainPath = Join-Path -Path $domainRoot -ChildPath $domainModule
    if (-not (Test-Path -LiteralPath $domainPath -PathType Leaf)) {
        throw "Required Atlas.TasksProcs domain module '$domainPath' is missing."
    }

    . $domainPath
}

Export-ModuleMember -Function @(
    'Disable-AtlasScheduledTask', 'Enable-AtlasScheduledTask', 'Remove-AtlasScheduledTask',
    'Stop-AtlasProcess'
)
