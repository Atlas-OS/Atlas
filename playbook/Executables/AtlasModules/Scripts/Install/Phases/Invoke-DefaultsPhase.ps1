# Defaults phase.
# Fresh installs initialize the toggle state store. Applying a toggle records its choice;
# default launcher labels alone do not create state. Upgrades and reapplies migrate the
# existing tree and re-apply known states from installed definitions, except the choice
# toggles the Choices step has just set when an update chooses again.
# Runs as TrustedInstaller; the state store is HKLM-only.

Assert-AtlasPrivilege -TrustedInstaller

$modulesRoot = Join-Path -Path (Split-Path -Parent (Split-Path -Parent $PSScriptRoot)) -ChildPath 'Modules'
Import-Module -Name (Join-Path $modulesRoot 'Atlas.Toggles\Atlas.Toggles.psd1') -Force -ErrorAction Stop

$context = Get-AtlasContext
if ($context.IsUpgrade) {
    # Choosing again, the Choices step has just applied the choice toggles whose records
    # differed from the choices, and recorded which, so replaying those would only repeat
    # it. The ones that already matched replay as when keeping choices.
    $exclude = @()
    if ($context.IsChoosingAgain) {
        . (Join-Path (Split-Path -Parent $PSScriptRoot) 'Tasks\Choices.ps1')
        $exclude = @((Get-AtlasChoicesRecord).Applied)
    }
    Invoke-AtlasToggleReapply -Exclude $exclude

    # Reconciliation report: every recorded state was just re-applied, here or by the
    # Choices step, so any remaining machine-scope drift is a declaration this Windows
    # build no longer honours.
    foreach ($item in @(Test-AtlasToggleDrift -Scope Machine)) {
        Write-AtlasLog -Level Warning -Message "Toggle '$($item.Toggle)' state '$($item.State)' drifts after replay: $($item.Kind) '$($item.Target)' $($item.Reason)."
    }
}
else {
    Initialize-AtlasToggleStateStore
}
