$windir = [Environment]::GetFolderPath('Windows')
& (Join-Path -Path $windir -ChildPath 'AtlasModules\initPowerShell.ps1')

Write-Title "Creating Desktop & Start Menu shortcuts..."

# Default user
$defaultShortcut = "$(Get-UserPath)\Atlas.lnk"
New-AtlasShortcut -Source "$windir\AtlasDesktop" -Destination $defaultShortcut -Icon "$windir\AtlasModules\Other\atlas-folder.ico,0"

# Do not enumerate or write loaded user profiles from TrustedInstaller. Existing-user
# setup is dispatched separately under the exact install-state-bound medium token; this entry
# point owns only the default profile and common Start Menu assets.

# Start menu shortcut
Copy-Item $defaultShortcut -Destination "$([Environment]::GetFolderPath('CommonStartMenu'))\Programs" -Force

Write-Title "Creating services restore shortcut..."
$desktop = "$windir\AtlasDesktop"
New-AtlasShortcut -Source "$desktop\9. Troubleshooting\Set services to defaults.cmd" -Destination "$desktop\6. Advanced Configuration\Services\Set services to defaults.lnk"
