# PreInstall phase.
# Prepares the machine before the main install runs: disables notifications so they do
# not fire mid-deployment, then runs disk cleanup so it can work in the background.
# Replaces the DISABLENOTIFS.cmd !cmd and the CLEANUP.ps1 !powerShell actions that
# custom.yml used to carry. Runs elevated (runas: currentUserElevated) so HKCU resolves
# to the interactive user and the cleanup has the rights it needs. Cleanup failing must
# not abort the install, so each step is wrapped and downgraded to a warning.

Assert-AtlasPrivilege -Administrator

$internalRoot = Join-Path -Path (Split-Path -Parent $PSScriptRoot) -ChildPath 'Internal'

# Prevent annoying notifications during deployment
try {
    & (Join-Path -Path $internalRoot -ChildPath 'Set-NotificationState.ps1') -Mode Disable
}
catch {
    Write-AtlasLog -Level Warning -Message "Disabling notifications failed: $($_.Exception.Message)"
}

# Disk Cleanup (kicks off cleanmgr in the background and clears temp/shadow copies)
try {
    & (Join-Path -Path $internalRoot -ChildPath 'Invoke-DiskCleanup.ps1')
}
catch {
    Write-AtlasLog -Level Warning -Message "Disk cleanup failed: $($_.Exception.Message)"
}
