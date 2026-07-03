# Atlas.Registry - registry engine module.
Set-StrictMode -Version 3.0

$domainRoot = Join-Path -Path $PSScriptRoot -ChildPath 'Domain'

foreach ($domainModule in @(
    'Paths.ps1'
    'Values.ps1'
    'Keys.ps1'
    'RegFile.ps1'
    'Sync.ps1'
    'Entries.ps1'
    'UserPaths.ps1'
)) {
    $domainPath = Join-Path -Path $domainRoot -ChildPath $domainModule
    if (-not (Test-Path -LiteralPath $domainPath -PathType Leaf)) {
        throw "Required Atlas.Registry domain module '$domainPath' is missing."
    }

    . $domainPath
}

Export-ModuleMember -Function @(
    'Resolve-AtlasRegistryPath', 'Get-AtlasActiveUserSid', 'Get-AtlasUserHives', 'Get-RegUserPaths',
    'Set-AtlasRegistryValue', 'Remove-AtlasRegistryValue', 'New-AtlasRegistryKey', 'Remove-AtlasRegistryKey',
    'Import-AtlasRegFile', 'Sync-AtlasDefaultUserHive', 'Invoke-AtlasRegistryEntries',
    'Get-UserPath', 'Get-SystemDrive'
)
