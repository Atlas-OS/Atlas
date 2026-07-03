# Public utility module surface.
$domainRoot = Join-Path -Path $PSScriptRoot -ChildPath 'Domain'

foreach ($domainModule in @(
    'Ui.ps1'
    'Processes.ps1'
    'ScheduledTasks.ps1'
)) {
    $domainPath = Join-Path -Path $domainRoot -ChildPath $domainModule
    if (-not (Test-Path -LiteralPath $domainPath -PathType Leaf)) {
        throw "Required utility domain module '$domainPath' is missing."
    }

    . $domainPath
}

Export-ModuleMember -Function Write-Title, Read-Pause, Read-MessageBox, Stop-ProcessesUnderRoots, Stop-TasksUnderRoots
