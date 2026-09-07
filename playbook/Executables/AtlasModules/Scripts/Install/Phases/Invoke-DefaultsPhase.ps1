# Defaults phase.
# Fresh installs initialize the toggle state store. Applying a toggle records its choice;
# default launcher labels alone do not create state. Upgrades and reapplies migrate the
# existing tree and re-apply known states from installed definitions.
# Runs as TrustedInstaller; the state store is HKLM-only.

Assert-AtlasPrivilege -TrustedInstaller

$modulesRoot = Join-Path -Path (Split-Path -Parent (Split-Path -Parent $PSScriptRoot)) -ChildPath 'Modules'
Import-Module -Name (Join-Path $modulesRoot 'Atlas.Toggles\Atlas.Toggles.psd1') -Force -ErrorAction Stop

if ((Get-AtlasContext).IsUpgrade) {
    Invoke-AtlasToggleReapply

    # Reconciliation report: every recorded state was just re-applied, so any remaining
    # machine-scope drift is a declaration this Windows build no longer honours.
    foreach ($item in @(Test-AtlasToggleDrift -Scope Machine)) {
        Write-AtlasLog -Level Warning -Message "Toggle '$($item.Toggle)' state '$($item.State)' drifts after replay: $($item.Kind) '$($item.Target)' $($item.Reason)."
    }
}
else {
    Initialize-AtlasToggleStateStore
}
