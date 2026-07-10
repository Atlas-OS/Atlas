# Companion of config-start-menu.psd1.
$ErrorActionPreference = 'Stop'
$windir = [Environment]::GetFolderPath('Windows')
$scriptsRoot = (Resolve-Path (Join-Path -Path $PSScriptRoot -ChildPath '..\..')).ProviderPath

# Set the Start Menu layout for every user.
& (Join-Path -Path $windir -ChildPath 'AtlasModules\Scripts\Internal\Set-StartLayout.ps1')

# Clear the Start Menu experience host cache so the new layout takes effect.
Import-Module -Name (Join-Path $scriptsRoot 'Modules\Atlas.Appx\Atlas.Appx.psd1') `
    -Force -ErrorAction Stop
Clear-AtlasAppxCache -Name 'Microsoft.Windows.StartMenuExperienceHost*'
