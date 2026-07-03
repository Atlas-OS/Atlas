# Companion of config-pins.psd1 (was Configuration\tweaks\qol\taskbar\config-pins.yml).
$ErrorActionPreference = 'Stop'
$windir = [Environment]::GetFolderPath('Windows')

# Resolve the user's chosen browser from the install options (was per-action option gates).
$browser = ''
if (Test-AtlasOption -Name 'install-another-browser') {
    if (Test-AtlasOption -Name 'browser-brave') { $browser = 'Brave' }
    elseif (Test-AtlasOption -Name 'browser-firefox') { $browser = 'Firefox' }
    elseif (Test-AtlasOption -Name 'browser-chrome') { $browser = 'Google Chrome' }
    elseif (Test-AtlasOption -Name 'browser-librewolf') { $browser = 'LibreWolf' }
}

# Temporary value read by Initialize-NewUser.ps1 to pin the taskbar for users created later.
$setupOptions = 'HKLM:\SOFTWARE\AtlasOS\SetupOptions'
if (-not (Test-Path -LiteralPath $setupOptions)) {
    New-Item -Path $setupOptions -Force | Out-Null
}
New-ItemProperty -LiteralPath $setupOptions -Name 'browser' -Value $browser -PropertyType String -Force | Out-Null

# Apply the taskbar pins to existing users, but not during OOBE (was oobe: false).
if (-not (Get-AtlasContext).IsOobe) {
    $taskbarPins = Join-Path -Path $windir -ChildPath 'AtlasModules\Scripts\Internal\Set-TaskbarPins.ps1'
    $location = Get-Location
    try {
        if ($browser) {
            & $taskbarPins $browser
        }
        else {
            & $taskbarPins
        }
    }
    finally {
        Set-Location -LiteralPath $location
    }
}
