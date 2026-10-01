# AppxSupport phase. Runs as TrustedInstaller, in this order: snapshot, stop the
# installing user's package processes, remove installed and provisioned packages,
# clean up Phone Link, write deprovision markers, then clear the user's caches.
# Required package failures are collected so cleanup still runs before the phase
# returns nonzero.
#
# Machine AppX work stays in this token and every package query and removal uses
# AllUsers. User-controlled cache trees are cleared by a child running as the
# installing user, never through a privileged token, and profile roots are never
# enumerated here.
# https://learn.microsoft.com/en-us/powershell/module/appx/remove-appxpackage

Assert-AtlasPrivilege -TrustedInstaller

$modulesRoot = Join-Path -Path (Split-Path -Parent (Split-Path -Parent $PSScriptRoot)) -ChildPath 'Modules'
Import-Module -Name (Join-Path $modulesRoot 'Atlas.Appx\Atlas.Appx.psd1') -Force -ErrorAction Stop

# Get current AppX packages to deprovision removed ones afterward. A failed snapshot is
# fatal before mutation because cleanup could not safely determine what Atlas removed.
Save-AtlasAppxSnapshot

# Quiesce Teams/Search in the exact install-state user's nonzero session before
# removal. This checked launch is process-only; cache mutation remains after removal
# and deprovisioning. This strict TI process never enumerates or terminates UI.
Invoke-AtlasUserAppxCacheCleanup -Mode AppxQuiesce

$requiredFailures = [System.Collections.Generic.List[string]]::new()
try {
    Invoke-AtlasAppxRemovalPlan
}
catch {
    $requiredFailures.Add($_.Exception.Message)
}

# Phone Link is removed on its own and best effort: removing it with the other
# packages broke Cross Device Experience Host installation.
try {
    Remove-AtlasPhoneLinkAppx
}
catch {
    Write-AtlasLog -Level Warning -Message "Removing Phone Link failed: $($_.Exception.Message)"
}

# Prevent removed provisioned applications from being restored by a feature update.
# https://learn.microsoft.com/en-us/windows/application-management/remove-provisioned-apps-during-update
try {
    Set-AtlasAppxDeprovisioned
}
catch {
    $message = "Deprovisioning removed AppX packages failed: $($_.Exception.Message)"
    $requiredFailures.Add($message)
    Write-AtlasLog -Level Error -Message $message
}

# Clear caches of Client.CBS and more (Start menu cache is cleared later).
try {
    Invoke-AtlasUserAppxCacheCleanup -Mode AppxSupport
}
catch {
    $message = "Clearing AppX caches failed: $($_.Exception.Message)"
    $requiredFailures.Add($message)
    Write-AtlasLog -Level Error -Message $message
}

if ($requiredFailures.Count -gt 0) {
    throw "The AppX removal plan failed after cleanup: $($requiredFailures -join ' | ')"
}
