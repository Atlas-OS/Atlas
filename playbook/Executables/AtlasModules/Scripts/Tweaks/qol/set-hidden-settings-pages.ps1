# Companion of set-hidden-settings-pages.psd1: hides broken/unused Settings pages.
# https://learn.microsoft.com/en-us/windows/uwp/launch-resume/launch-settings-app
$ErrorActionPreference = 'Stop'

$value = 'hide:recovery;maps;maps-downloadmaps;privacy;privacy-feedback;privacy-activityhistory;search-permissions;privacy-general;sync;mobile-devices;mobile-devices-addphone;workplace;family-group;deviceusage;home'

$key = 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\Explorer'
if (-not (Test-Path -LiteralPath $key)) {
    New-Item -Path $key -Force | Out-Null
}
Set-ItemProperty -LiteralPath $key -Name 'SettingsPageVisibility' -Value $value -Type String -Force
