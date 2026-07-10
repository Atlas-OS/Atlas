# Finalize phase.
# Last step before custom.yml unloads the default-user hive. Order is correctness-critical:
#   1. Sync-AtlasDefaultUserHive re-copies every recorded HKCU key into
#      HKU\AME_UserHive_Default while it is still loaded; if it runs after the hive is
#      unloaded, new-user propagation is silently lost.
# Runs elevated (runas: currentUserElevated).

Assert-AtlasPrivilege -Administrator

$modulesRoot = Join-Path -Path (Split-Path -Parent $PSScriptRoot) -ChildPath 'Modules'
Import-Module -Name (Join-Path $modulesRoot 'Atlas.Registry\Atlas.Registry.psd1') -Force -ErrorAction Stop

# Mirror recorded HKCU keys into the loaded default-user hive (must run before unload)
try {
    Sync-AtlasDefaultUserHive
}
catch {
    Write-AtlasLog -Level Warning -Message "Syncing the default-user hive failed: $($_.Exception.Message)"
}
