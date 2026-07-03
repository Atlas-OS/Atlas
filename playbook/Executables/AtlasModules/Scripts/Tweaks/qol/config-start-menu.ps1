# Companion of config-start-menu.psd1.
$ErrorActionPreference = 'Stop'
$windir = [Environment]::GetFolderPath('Windows')

# Set the Start Menu layout for every user.
& (Join-Path -Path $windir -ChildPath 'AtlasModules\Scripts\Internal\Set-StartLayout.ps1')

# Clear the Start Menu experience host cache so the new layout takes effect.
Import-Module Atlas.Appx -Force
Clear-AtlasAppxCache -Name 'Microsoft.Windows.StartMenuExperienceHost*'
