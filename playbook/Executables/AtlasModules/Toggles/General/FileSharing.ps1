# Fresh install and this toggle share the Atlas.Network File Sharing functions; the
# engine owns the closing line, the restart prompt and records only the completed
# machine transition.
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

    # NetworkNavigationPane owns this independent choice and its first-login replay.
    # Replaying FileSharing must not replace it or ask the question again.
    if ($Toggle.Silent -or
        -not (Read-AtlasYesNo -Question 'Add Network to the File Explorer navigation pane?')) {
        return
    }
    Invoke-AtlasToggle -Name 'NetworkNavigationPane' -State 'Enable' -StateRoot $Toggle.StateRoot `
        -NoExplorerRestart -DeferPostAction
}
