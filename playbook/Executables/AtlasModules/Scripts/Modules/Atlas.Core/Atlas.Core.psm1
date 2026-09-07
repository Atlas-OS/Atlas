# Atlas.Core - core framework module.
$domainRoot = Join-Path -Path $PSScriptRoot -ChildPath 'Domain'

foreach ($domainModule in @(
    'Data.ps1'
    'Context.ps1'
    'Logging.ps1'
    'Native.ps1'
    'TrustedInstallerProcess.ps1'
    'Privilege.ps1'
    'Process.ps1'
    'Ui.ps1'
    'RunAsUser.ps1'
)) {
    $domainPath = Join-Path -Path $domainRoot -ChildPath $domainModule
    if (-not (Test-Path -LiteralPath $domainPath -PathType Leaf)) {
        throw "Required Atlas.Core domain module '$domainPath' is missing."
    }

    . $domainPath
}

Export-ModuleMember -Function @(
    'Import-AtlasDataFile', 'Import-AtlasModule',
    'Initialize-AtlasNativeType',
    'Get-AtlasContext', 'Test-AtlasOption',
    'Write-AtlasLog', 'Start-AtlasPhase', 'Stop-AtlasPhase',
    'Set-AtlasLogConsoleStyle', 'Get-AtlasLogConsoleStyle', 'Get-AtlasInstallLogPath',
    'Test-AtlasAdmin', 'Test-AtlasSystem', 'Test-AtlasTrustedInstaller', 'Assert-AtlasPrivilege', 'Invoke-AtlasTrustedInstaller', 'Invoke-AtlasAsUser', 'Get-AtlasUserProcessCommandLine',
    'ConvertTo-AtlasWindowsArgumentString', 'Invoke-AtlasHiddenProcess',
    'Write-AtlasTitle', 'Write-AtlasBlankLine', 'Write-AtlasNote', 'Write-AtlasStep', 'Write-AtlasWarning',
    'Write-AtlasSuccess', 'Write-AtlasFailure', 'Write-AtlasPartial', 'Write-AtlasNextStep',
    'Write-AtlasManualStep', 'Write-AtlasRestartNotice', 'Write-AtlasNotApplied',
    'Write-AtlasCompletion', 'Reset-AtlasRunOutcome', 'Get-AtlasRunOutcome', 'Set-AtlasRunOutcome',
    'Read-AtlasYesNo', 'Read-AtlasChoice', 'Wait-AtlasContinue', 'Wait-AtlasExit',
    'Read-MessageBox'
)
