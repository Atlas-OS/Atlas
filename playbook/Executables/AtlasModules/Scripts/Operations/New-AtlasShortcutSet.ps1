$windir = [Environment]::GetFolderPath('Windows')
. (Join-Path -Path $windir -ChildPath 'AtlasModules\Scripts\Initialize-AtlasPowerShell.ps1')

Write-AtlasStep -Text 'Creating Desktop and Start Menu shortcuts...'

# Default user
$defaultShortcut = "$(Get-UserPath)\Atlas.lnk"
New-AtlasShortcut -Source "$windir\AtlasDesktop" -Destination $defaultShortcut -Icon "$windir\AtlasModules\Other\atlas-folder.ico,0"

# Do not enumerate or write loaded user profiles from TrustedInstaller. The installing
# user's setup runs separately in that user's own token; this script handles only the
# default profile and the common Start Menu.

# Start menu shortcut
Copy-Item $defaultShortcut -Destination "$([Environment]::GetFolderPath('CommonStartMenu'))\Programs" -Force

Write-AtlasStep -Text 'Creating the services restore shortcut...'
$desktop = "$windir\AtlasDesktop"
New-AtlasShortcut -Source "$desktop\9. Troubleshooting\Set services to defaults.cmd" -Destination "$desktop\6. Advanced Configuration\Services\Set services to defaults.lnk"
