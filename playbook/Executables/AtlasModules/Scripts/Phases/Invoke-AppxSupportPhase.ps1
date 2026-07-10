# AppxSupport phase.
# Runs as the elevated interactive user selected by the AME shim. Ordering is deliberate:
# snapshot, package-process stop, installed/provisioned removal, Phone Link cleanup,
# deprovision markers, then cache clearing. Required package failures are aggregated so
# cleanup still runs before the checked phase returns nonzero to AME.
#
# This is a deliberate privilege reduction from AME's former TI/KPH-backed AppX action:
# Microsoft requires administrator permission for the all-user package cmdlets, not a
# TrustedInstaller token. Staying in the elevated interactive-user context also preserves
# the snapshot's installing-user semantics.
# https://learn.microsoft.com/en-us/powershell/module/appx/remove-appxpackage

Assert-AtlasPrivilege -Administrator

$modulesRoot = Join-Path -Path (Split-Path -Parent $PSScriptRoot) -ChildPath 'Modules'
Import-Module -Name (Join-Path $modulesRoot 'Atlas.Appx\Atlas.Appx.psd1') -Force -ErrorAction Stop
Import-Module -Name (Join-Path $modulesRoot 'Atlas.TasksProcs\Atlas.TasksProcs.psd1') -Force -ErrorAction Stop

# Get current AppX packages to deprovision removed ones afterward. A failed snapshot is
# fatal before mutation because cleanup could not safely determine what Atlas removed.
Save-AtlasAppxSnapshot

# Stop legacy and current Teams processes so their registrations are not in use.
Stop-AtlasProcess -Name 'msteams*', 'ms-teams*'

$requiredFailures = [System.Collections.Generic.List[string]]::new()
try {
    Invoke-AtlasAppxRemovalPlan
}
catch {
    $requiredFailures.Add($_.Exception.Message)
}

# Removing Phone Link through the former AME action caused Cross Device Experience Host
# installation issues. Preserve its separate best-effort PowerShell path.
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
    Stop-AtlasProcess -Name 'SearchHost*', 'SearchApp*'
    Clear-AtlasAppxCache -Name '*MicrosoftWindows.Client.CBS*', '*Microsoft.Windows.Search*', '*Microsoft.Windows.SecHealthUI*'
}
catch {
    $message = "Clearing AppX caches failed: $($_.Exception.Message)"
    $requiredFailures.Add($message)
    Write-AtlasLog -Level Error -Message $message
}

if ($requiredFailures.Count -gt 0) {
    throw "The AppX removal plan failed after cleanup: $($requiredFailures -join ' | ')"
}
