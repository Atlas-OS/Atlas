# Companion for the VbsState toggle: turns Virtualisation-Based Security and Memory Integrity
# on or off. Set-AtlasVbsState runs as Administrator when you run a launcher and when an
# update replays the recorded state. Test-AtlasVbsStateReplayApplicable decides during update
# replay whether the recorded state still applies.

function Set-AtlasVbsState {
    param($Toggle)

    # The state name is the Set-AtlasVbsConfiguration -State value: Disable or Enable.
    Import-AtlasModule -Name Atlas.Security
    Set-AtlasVbsConfiguration -State $Toggle.State
}

function Test-AtlasVbsStateReplayApplicable {
    param($Toggle)

    # A choice that policy or a UEFI lock now refuses would fail every update that
    # replays it, so its record is cleared instead. The reason goes to the log.
    Import-AtlasModule -Name Atlas.Security
    $reason = Test-AtlasVbsChange -State $Toggle.State
    if ($null -ne $reason) {
        $change = if ($Toggle.State -ceq 'Disable') { 'turned off' } else { 'turned on' }
        Write-AtlasLog -Message "VBS can't be ${change}: $reason."
    }
    return $null -eq $reason
}
