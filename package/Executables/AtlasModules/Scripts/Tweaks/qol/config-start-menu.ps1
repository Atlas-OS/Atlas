# Companion of config-start-menu.psd1.
$ErrorActionPreference = 'Stop'

# Set the Start Menu layout for every user.
Import-AtlasModule -Name Atlas.Shell
Set-AtlasStartLayout

# Clear the Start Menu experience host cache so the new layout takes effect.
Import-AtlasModule -Name Atlas.Appx
Invoke-AtlasUserAppxCacheCleanup -Mode StartMenu
