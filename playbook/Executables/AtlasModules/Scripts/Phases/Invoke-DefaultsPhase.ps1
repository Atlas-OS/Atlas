# Defaults phase.
# Fresh installs initialize the toggle state store before the install plan imports the
# DEFAULT.reg beside the extracted playbook. Upgrades and reapplies migrate the existing
# tree and re-apply known states from installed definitions.
# Runs as TrustedInstaller; the state store and imported seed are HKLM-only.

Assert-AtlasPrivilege -TrustedInstaller

$modulesRoot = Join-Path -Path (Split-Path -Parent $PSScriptRoot) -ChildPath 'Modules'
Import-Module -Name (Join-Path $modulesRoot 'Atlas.Toggles\Atlas.Toggles.psd1') -Force -ErrorAction Stop

if ((Get-AtlasContext).IsUpgrade) {
    Invoke-AtlasToggleReapply
}
else {
    Initialize-AtlasToggleStateStore
}
