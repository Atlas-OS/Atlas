# Companion of disable-core-isolation.psd1.
$ErrorActionPreference = 'Stop'

# On an update, a choice made since with the Core Isolation (VBS) launchers stays, as
# every recorded toggle does: Defaults has already replayed it.
if ((Get-AtlasContext).IsUpgrade) {
    Import-AtlasModule -Name Atlas.Toggles
    $record = Get-AtlasToggleState -Name VbsState
    if ($null -ne $record -and $null -ne $record.State) {
        Write-AtlasLog -Message "Keeping the recorded VbsState choice (state $($record.State)) instead of disabling VBS."
        return
    }
}
Import-AtlasModule -Name Atlas.Security
Set-AtlasVbsConfiguration -State Disable -SkipWhenPolicyConflicts
