# Companion of set-hidden-settings-pages.psd1: hides broken/unused Settings pages. The
# hidden list differs between Windows 10 and Windows 11 (build 22000+).
# https://learn.microsoft.com/en-us/windows/uwp/launch-resume/launch-settings-app
$ErrorActionPreference = 'Stop'

$build = 0
try {
    $build = [int](Get-ItemProperty -Path 'HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion' -Name CurrentBuildNumber -ErrorAction Stop).CurrentBuildNumber
}
catch {
    $build = 0
}

if ($build -ge 22000) {
    # Windows 11
    $value = 'hide:recovery;maps;maps-downloadmaps;privacy;privacy-feedback;privacy-activityhistory;search-permissions;privacy-general;sync;mobile-devices;mobile-devices-addphone;workplace;family-group;deviceusage;home'
}
else {
    # Windows 10
    $value = 'hide:recovery;maps;maps-downloadmaps;privacy;privacy-speechtyping;privacy-speech;privacy-feedback;privacy-activityhistory;search-permissions;privacy-general;sync;mobile-devices;mobile-devices-addphone;workplace;backup'
}

$key = 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\Explorer'
if (-not (Test-Path -LiteralPath $key)) {
    New-Item -Path $key -Force | Out-Null
}
Set-ItemProperty -LiteralPath $key -Name 'SettingsPageVisibility' -Value $value -Type String -Force
