# Atlas.Shell - shell configuration module.
Set-StrictMode -Version 3.0

# No -Force: a nested forced import unloads the caller's copy in Windows PowerShell 5.1.
foreach ($dependencyManifest in @(
    '..\Atlas.Core\Atlas.Core.psd1'
    '..\Atlas.Registry\Atlas.Registry.psd1'
    '..\Atlas.Shortcuts\Atlas.Shortcuts.psd1'
)) {
    $manifestPath = Join-Path -Path $PSScriptRoot -ChildPath $dependencyManifest
    if (-not (Test-Path -LiteralPath $manifestPath -PathType Leaf)) {
        throw "Required Atlas.Shell dependency '$manifestPath' is missing."
    }
    Import-Module -Name $manifestPath -ErrorAction Stop
}

# Helpers that start other processes stay in Scripts\Operations; the interactive
# Send To flow launches the session-filtered shell refresh from there.
$script:AtlasShellOperationsRoot = [IO.Path]::GetFullPath(
    (Join-Path -Path $PSScriptRoot -ChildPath '..\..\Operations')
)

$domainRoot = Join-Path -Path $PSScriptRoot -ChildPath 'Domain'

foreach ($domainModule in @(
    'SettingsPages.ps1'
    'FileAssociations.ps1'
    'SendTo.ps1'
    'ContextMenu.ps1'
    'Start.ps1'
    'Taskbar.ps1'
    'Home.ps1'
)) {
    $domainPath = Join-Path -Path $domainRoot -ChildPath $domainModule
    if (-not (Test-Path -LiteralPath $domainPath -PathType Leaf)) {
        throw "Required Atlas.Shell domain module '$domainPath' is missing."
    }

    . $domainPath
}

Export-ModuleMember -Function @(
    'Set-AtlasSettingsPageVisibility',
    'Set-AtlasFileAssociations',
    'Set-AtlasSendToContextMenu',
    'ConvertTo-AtlasShellWindowsArgument', 'Get-AtlasTakeOwnershipArgumentPlan', 'Assert-AtlasTakeOwnershipTree',
    'Set-AtlasStartLayout',
    'Set-AtlasTaskbarPins',
    'Add-AtlasMusicVideosToHome'
)
