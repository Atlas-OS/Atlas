# Software phase.
# Installs the initial utilities and the user's selected browser/toolbox. Runs elevated
# (runas: currentUserElevated); downloads happen here at install time, which is why
# start.yml keeps the phase call inside the NO LOCAL BUILD marker block.
# Component failures are logged as warnings and never halt the playbook.

Assert-AtlasPrivilege -Administrator

$modulesRoot = Join-Path -Path (Split-Path -Parent $PSScriptRoot) -ChildPath 'Modules'
Import-Module -Name (Join-Path $modulesRoot 'Atlas.Software\Atlas.Software.psd1') -Force -ErrorAction Stop

$context = Get-AtlasContext

# Initial software: Visual C++ Runtimes, NanaZip/7-Zip, DirectX (fresh installs only)
if (-not $context.IsUpgrade) {
    Install-AtlasSoftware -Component VCRedist, SevenZip, DirectX | Out-Null
}

# Toolbox
if (Test-AtlasOption -Name 'install-toolbox') {
    Install-AtlasSoftware -Component Toolbox | Out-Null
}

# Browsers ('browser-*' options are only set when 'install-another-browser' was picked;
# AME Wizard resolves that dependency before the option flags are written)
if (Test-AtlasOption -Name 'browser-brave') {
    Install-AtlasSoftware -Component Brave | Out-Null
}
if (Test-AtlasOption -Name 'browser-firefox') {
    Install-AtlasSoftware -Component Firefox | Out-Null
}
if (Test-AtlasOption -Name 'browser-librewolf') {
    Install-AtlasSoftware -Component LibreWolf | Out-Null
}
if (Test-AtlasOption -Name 'browser-chrome') {
    Install-AtlasSoftware -Component Chrome | Out-Null
}
