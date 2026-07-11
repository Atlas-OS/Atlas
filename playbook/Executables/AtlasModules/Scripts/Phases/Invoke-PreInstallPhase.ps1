# PreInstall phase.
# Prepares the machine before the main install runs: disables notifications so they do
# not fire mid-deployment, then runs disk cleanup so it can work in the background.
# Runs elevated (runas: currentUserElevated) so HKCU resolves to the interactive user
# and the cleanup has the rights it needs. The security migration is required; later
# convenience cleanup is best-effort and downgraded to a warning.

Assert-AtlasPrivilege -Administrator

$internalRoot = Join-Path -Path (Split-Path -Parent $PSScriptRoot) -ChildPath 'Internal'

# This is a required security migration, not best-effort cleanup. It executes after the
# new payload is copied and before any default-state replay can recreate legacy commands.
$legacyMigration = Join-Path -Path $internalRoot -ChildPath 'Remove-AtlasLegacyElevationArtifacts.ps1'
if (-not (Test-Path -LiteralPath $legacyMigration -PathType Leaf)) {
    throw "Required legacy elevation migration '$legacyMigration' is missing."
}
$legacyMigrationOutput = @(& $legacyMigration)
if ($legacyMigrationOutput.Count -ne 1) {
    throw "Required legacy elevation migration returned $($legacyMigrationOutput.Count) result(s); expected exactly one."
}
$legacyMigrationResult = $legacyMigrationOutput[0]
if ($legacyMigrationResult -isnot [Management.Automation.PSCustomObject]) {
    throw 'Required legacy elevation migration did not return a typed result object.'
}
$resultProperties = @($legacyMigrationResult.PSObject.Properties | ForEach-Object { [string]$_.Name })
if ($resultProperties.Count -ne 2 -or $resultProperties -cnotcontains 'AppliedCount' -or
    $resultProperties -cnotcontains 'WarningCount') {
    throw 'Required legacy elevation migration returned an unsupported result shape.'
}
$integralTypeCodes = @('SByte', 'Byte', 'Int16', 'UInt16', 'Int32', 'UInt32', 'Int64', 'UInt64')
foreach ($propertyName in @('AppliedCount', 'WarningCount')) {
    $property = $legacyMigrationResult.PSObject.Properties[$propertyName]
    $value = if ($null -ne $property) { $property.Value } else { $null }
    $typeCode = if ($null -ne $value) { [Type]::GetTypeCode($value.GetType()).ToString() } else { $null }
    if ($integralTypeCodes -cnotcontains $typeCode -or [decimal]$value -lt 0) {
        throw "Required legacy elevation migration returned an invalid $propertyName value."
    }
}
Write-AtlasLog -Message (
    'Legacy elevation migration applied {0} change(s) and retained {1} customized user artifact(s).' -f
    $legacyMigrationResult.AppliedCount,
    $legacyMigrationResult.WarningCount
)

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
