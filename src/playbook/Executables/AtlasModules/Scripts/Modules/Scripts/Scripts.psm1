# Public system-script orchestration module.
Set-StrictMode -Version 3.0

$script:AtlasWindowsDirectory = [Environment]::GetFolderPath('Windows')
$domainRoot = Join-Path -Path $PSScriptRoot -ChildPath 'Domain'

foreach ($domainModule in @(
    'Backup.ps1'
    'ClientCbs.ps1'
    'Security.ps1'
    'Devices.ps1'
    'FileAssociations.ps1'
    'Performance.ps1'
    'ProfilePictures.ps1'
    'Orchestration.ps1'
)) {
    $domainPath = Join-Path -Path $domainRoot -ChildPath $domainModule
    if (-not (Test-Path -LiteralPath $domainPath -PathType Leaf)) {
        throw "Required system-script domain module '$domainPath' is missing."
    }

    . $domainPath
}

Export-ModuleMember -Function Invoke-AllSystemScripts
