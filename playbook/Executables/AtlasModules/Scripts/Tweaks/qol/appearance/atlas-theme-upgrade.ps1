# Companion of atlas-theme-upgrade.psd1 (RunAs = UserElevated, upgrades only).
# On upgrades the theme file is already applied; this just refreshes the "recent themes"
# MRU in the user's session so the Atlas theme stays selected. Best-effort.
$ErrorActionPreference = 'Continue'

& (Join-Path -Path ([Environment]::GetFolderPath('Windows')) -ChildPath 'AtlasModules\initPowerShell.ps1')
Import-Module Atlas.Themes -ErrorAction SilentlyContinue

Set-AtlasThemeMru
