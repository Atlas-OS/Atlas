# Finalize phase.
# Last step before custom.yml unloads the default-user hive. Order is correctness-critical:
#   1. Complete-AtlasHkcuDeltaJournal freezes and durably binds the exact typed
#      mutation stream.
#   2. Sync-AtlasDefaultUserHive replays that committed stream into
#      HKU\AME_UserHive_Default while it is still loaded; if it runs after the hive is
#      unloaded, new-user propagation is silently lost.
# Runs elevated (runas: currentUserElevated).

Assert-AtlasPrivilege -Administrator

$modulesRoot = Join-Path -Path (Split-Path -Parent $PSScriptRoot) -ChildPath 'Modules'
Import-Module -Name (Join-Path $modulesRoot 'Atlas.Registry\Atlas.Registry.psd1') -Force -ErrorAction Stop

# Freeze the exact Atlas-owned HKCU mutation stream before replay. Completion and
# replay are both required Finalize postconditions: either failure must propagate
# through Invoke-AtlasInstall so AME cannot unload the hive and report success.
$null = Complete-AtlasHkcuDeltaJournal
Sync-AtlasDefaultUserHive
