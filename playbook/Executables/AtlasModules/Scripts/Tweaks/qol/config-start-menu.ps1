# Companion of config-start-menu.psd1 (was Configuration\tweaks\qol\config-start-menu.yml).
$ErrorActionPreference = 'Stop'
$windir = [Environment]::GetFolderPath('Windows')

# Set the Start Menu layout for every user (was Internal\Set-StartLayout.ps1).
& (Join-Path -Path $windir -ChildPath 'AtlasModules\Scripts\Internal\Set-StartLayout.ps1')

# Clear the Start Menu experience host cache so the new layout takes effect
# (was the AME '!appx: {operation: clearCache}' action).
Import-Module Atlas.Appx -Force
Clear-AtlasAppxCache -Name 'Microsoft.Windows.StartMenuExperienceHost*'
