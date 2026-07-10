# Defaults phase.
# Fresh installs import DEFAULT.reg directly from the playbook directory (an exeDir PowerShell
# in atlas\default.yml) because it reads the .reg beside the playbook, not from %windir%;
# that action stays in YAML and runs after this phase has protected the state root. Upgrades
# instead migrate the existing tree and re-apply known states from installed definitions.
# Runs elevated (runas: currentUserElevated).

Assert-AtlasPrivilege -Administrator

$modulesRoot = Join-Path -Path (Split-Path -Parent $PSScriptRoot) -ChildPath 'Modules'
Import-Module -Name (Join-Path $modulesRoot 'Atlas.Toggles\Atlas.Toggles.psd1') -Force -ErrorAction Stop

if ((Get-AtlasContext).IsUpgrade) {
    Invoke-AtlasToggleReapply
}
else {
    Initialize-AtlasToggleStateStore
}
