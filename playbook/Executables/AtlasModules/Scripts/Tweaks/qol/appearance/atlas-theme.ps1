# Companion of atlas-theme.psd1 (RunAs = UserElevated, fresh installs).
# Applies the Atlas theme + lock-screen in the interactive user's session (COM
# IThemeManager / WinRT lock-screen need the running shell). Best-effort: theming is
# cosmetic, so a failure here must not abort the install.
$ErrorActionPreference = 'Continue'

& (Join-Path -Path ([Environment]::GetFolderPath('Windows')) -ChildPath 'AtlasModules\initPowerShell.ps1')
Import-Module Atlas.Themes -ErrorAction SilentlyContinue

$themePath = Join-Path -Path ([Environment]::GetFolderPath('Windows')) -ChildPath 'Resources\Themes\atlas-v0.5.x-dark.theme'
Set-Theme -Path $themePath
Set-ThemeMRU
Set-LockscreenImage

# Disable the rotating lock-screen "fun facts" for every provisioned account
# (Enterprise/Education only). Dynamic subkeys, so it can't be a static Registry entry.
$creativeKey = 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Authentication\LogonUI\Creative'
if (Test-Path -LiteralPath $creativeKey) {
    foreach ($userKey in (Get-ChildItem -LiteralPath $creativeKey).PSPath) {
        Set-ItemProperty -LiteralPath $userKey -Name 'RotatingLockScreenEnabled' -Type DWord -Value 0 -Force -ErrorAction SilentlyContinue
    }
}
