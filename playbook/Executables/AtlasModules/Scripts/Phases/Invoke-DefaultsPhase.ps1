# Defaults phase.
# Fresh installs import DEFAULT.reg directly from the playbook directory (an exeDir !cmd
# in atlas\default.yml) because it reads the .reg beside the playbook, not from %windir%;
# that action stays in YAML. This phase only handles the upgrade branch: re-apply every
# recorded toggle whose state is not 0 by re-running its recorded launcher silently.
# Runs elevated (runas: currentUserElevated, onUpgrade: true).

Assert-AtlasPrivilege -Administrator

$modulesRoot = Join-Path -Path (Split-Path -Parent $PSScriptRoot) -ChildPath 'Modules'
Import-Module -Name (Join-Path $modulesRoot 'Atlas.Toggles\Atlas.Toggles.psd1') -Force -ErrorAction Stop

if ((Get-AtlasContext).IsUpgrade) {
    Invoke-AtlasToggleReapply
}
