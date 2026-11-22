# Companion of config-pins.psd1.
$ErrorActionPreference = 'Stop'

# Resolve the user's chosen browser from the install options.
$browser = ''
if (Test-AtlasOption -Name 'install-another-browser') {
    if (Test-AtlasOption -Name 'browser-brave') { $browser = 'Brave' }
    elseif (Test-AtlasOption -Name 'browser-firefox') { $browser = 'Firefox' }
    elseif (Test-AtlasOption -Name 'browser-chrome') { $browser = 'Google Chrome' }
    elseif (Test-AtlasOption -Name 'browser-librewolf') { $browser = 'LibreWolf' }
}

# Value read by Initialize-NewUser.ps1 for the installing user and users created later.
$setupOptions = 'HKLM:\SOFTWARE\AtlasOS\SetupOptions'
if (-not (Test-Path -LiteralPath $setupOptions)) {
    New-Item -Path $setupOptions -Force | Out-Null
}
New-ItemProperty -LiteralPath $setupOptions -Name 'browser' -Value $browser -PropertyType String -Force | Out-Null
