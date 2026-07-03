# Software phase.
# Installs the initial utilities and the user's selected browser/toolbox, replacing
# the SOFTWARE.ps1/LIBREWOLF.ps1 calls in atlas\start.yml. Runs elevated
# (runas: currentUserElevated); downloads happen here at install time, which is why
# start.yml keeps the phase call inside the NO LOCAL BUILD marker block.
# Component failures are logged as warnings (software installs never halted the playbook).

Assert-AtlasPrivilege -Administrator

Import-Module Atlas.Software -Force

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
