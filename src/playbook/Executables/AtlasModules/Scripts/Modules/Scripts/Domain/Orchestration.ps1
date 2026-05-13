# System script domain functions: Orchestration

function Invoke-AllSystemScripts {
    Write-Host "Running scripts"
    Backup-AtlasServices
    Update-ClientCBS
    Disable-CoreIsolation
    Disable-DeviceSet
    Set-FileAssociations -Browser "default"
    Disable-Mitigations
    Optimize-PowerShellStartup
    Set-ProfilePictures
    Set-PowerSettings -DisablePowerSaving -DisableHibernation
}
