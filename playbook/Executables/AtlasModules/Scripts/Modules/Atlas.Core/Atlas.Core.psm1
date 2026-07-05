# Atlas.Core - core framework module.
$domainRoot = Join-Path -Path $PSScriptRoot -ChildPath 'Domain'

foreach ($domainModule in @(
    'Context.ps1'
    'Logging.ps1'
    'Privilege.ps1'
    'Ui.ps1'
    'Processes.ps1'
    'ScheduledTasks.ps1'
    'RunAsUser.ps1'
)) {
    $domainPath = Join-Path -Path $domainRoot -ChildPath $domainModule
    if (-not (Test-Path -LiteralPath $domainPath -PathType Leaf)) {
        throw "Required Atlas.Core domain module '$domainPath' is missing."
    }

    . $domainPath
}

Export-ModuleMember -Function @(
    'Get-AtlasContext', 'Test-AtlasOption', 'New-AtlasFlag', 'Test-AtlasFlag',
    'Write-AtlasLog', 'Start-AtlasPhase', 'Stop-AtlasPhase',
    'Test-AtlasAdmin', 'Test-AtlasTrustedInstaller', 'Assert-AtlasPrivilege', 'Invoke-AtlasTrustedInstaller', 'Invoke-AtlasAsUser', 'Get-AtlasUserProcessCommandLine',
    'Write-Title', 'Read-Pause', 'Read-MessageBox',
    'Stop-ProcessesUnderRoots', 'Stop-TasksUnderRoots'
)
