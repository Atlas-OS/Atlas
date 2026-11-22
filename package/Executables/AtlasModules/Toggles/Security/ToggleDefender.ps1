# Companion for the ToggleDefender toggle: removes or restores Windows Defender through the
# NoDefender package. Select-AtlasDefenderToggleState runs first, in the administrator window:
# it shows the menu and its warning and picks an internal state, the same pattern as Enable
# Search Indexing. That state's function then runs in the silent TrustedInstaller broker.
# Nothing is recorded.

function Select-AtlasDefenderToggleState {
    param($Toggle)

    if ($Toggle.Silent) {
        throw 'Choosing whether to enable or disable Windows Defender needs an interactive window.'
    }
    Import-AtlasModule -Name Atlas.Security
    return Read-AtlasDefenderStateChoice
}

function Invoke-AtlasDefenderToggle {
    param($Toggle)

    # Reached only by a direct silent request for the public state, which has no
    # choice to apply; the interactive path never runs this action.
    [void]$Toggle
    throw 'Toggle Defender needs an interactive window to choose between enabling and disabling Windows Defender.'
}

function Disable-AtlasDefenderToggle {
    param($Toggle)

    Import-AtlasModule -Name Atlas.Security
    Set-AtlasDefenderState -State Disable -Silent:$Toggle.Silent
    Set-AtlasDefenderToggleChoice -Option 'defender-disable'
}

function Enable-AtlasDefenderToggle {
    param($Toggle)

    Import-AtlasModule -Name Atlas.Security
    Set-AtlasDefenderState -State Enable -Silent:$Toggle.Silent
    Set-AtlasDefenderToggleChoice -Option 'defender-enable'
}

function Set-AtlasDefenderToggleChoice {
    param([string]$Option)

    # The Defender install choice now describes this change, which takes effect at the
    # restart the toggle asks for. Defender has already changed, so a record that
    # can't be written is a warning; the next install records what the PC has.
    Import-AtlasModule -Name Atlas.State
    try {
        $null = Set-AtlasStateChoice -Option $Option
    }
    catch {
        Write-AtlasLog -Level Warning -Message "Couldn't record '$Option' in the Atlas state document: $($_.Exception.Message)" -ErrorRecord $_
    }
}
