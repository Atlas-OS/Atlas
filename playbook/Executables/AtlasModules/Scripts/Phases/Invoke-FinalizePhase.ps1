# Finalize phase.
# Last step before custom.yml unloads the default-user hive. Order is correctness-critical:
#   1. Sync-AtlasDefaultUserHive re-copies every recorded HKCU key into
#      HKU\AME_UserHive_Default while it is still loaded (the APPLYDUHIVE.ps1 replacement);
#      if it runs after the hive is unloaded, new-user propagation is silently lost.
#   2. Repair-RegistryPaths.ps1 rewrites any stale AtlasDesktop launcher paths recorded under
#      HKLM\SOFTWARE\AtlasOS\Services so toggle re-apply keeps working after upgrades.
# Runs elevated (runas: currentUserElevated).

Assert-AtlasPrivilege -Administrator

Import-Module Atlas.Registry -Force

$internalRoot = Join-Path -Path (Split-Path -Parent $PSScriptRoot) -ChildPath 'Internal'

# Mirror recorded HKCU keys into the loaded default-user hive (must run before unload)
try {
    Sync-AtlasDefaultUserHive
}
catch {
    Write-AtlasLog -Level Warning -Message "Syncing the default-user hive failed: $($_.Exception.Message)"
}

# Correct any stale registry launcher paths
try {
    & (Join-Path -Path $internalRoot -ChildPath 'Repair-RegistryPaths.ps1')
}
catch {
    Write-AtlasLog -Level Warning -Message "Correcting registry paths failed: $($_.Exception.Message)"
}
