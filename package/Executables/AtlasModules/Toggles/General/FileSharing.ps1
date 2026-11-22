# Companion for the FileSharing toggle: applies file sharing through the Atlas.Network
# functions the fresh install uses. Set-AtlasFileSharingMachineState runs as Administrator
# when you run a launcher, when the install applies the toggle and when an update replays the
# recorded state. Add-AtlasFileSharingNetworkNavigationPane runs in your own unelevated
# process after Enable, and is replayed for each new account at first sign-in. The engine owns
# the closing line and the restart prompt, and records the state only after the machine part
# completes.

function Set-AtlasFileSharingMachineState {
    param($Toggle)

    Import-AtlasModule -Name Atlas.Network
    $enable = $Toggle.State -ceq 'Enable'
    $parameters = @{ Silent = [bool]$Toggle.Silent }
    if ($enable) {
        if (-not [string]::IsNullOrWhiteSpace([string]$Toggle.StateRoot)) {
            $parameters['StateRoot'] = [string]$Toggle.StateRoot
        }
        Enable-AtlasFileSharing @parameters
    }
    else {
        Disable-AtlasFileSharing @parameters
    }
}

function Add-AtlasFileSharingNetworkNavigationPane {
    param($Toggle)

    # NetworkNavigationPane owns this independent choice and its first sign-in replay.
    # Replaying FileSharing must not replace it or ask the question again.
    if ($Toggle.Silent -or
        -not (Read-AtlasYesNo -Question 'Add Network to the File Explorer navigation pane?')) {
        return
    }
    Invoke-AtlasToggle -Name 'NetworkNavigationPane' -State 'Enable' -StateRoot $Toggle.StateRoot `
        -NoExplorerRestart -DeferPostAction
}
