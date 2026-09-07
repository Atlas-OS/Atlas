# The menu and its consequences warning run in the interactive administrator process;
# the chosen package operation crosses the silent TrustedInstaller broker as a fixed
# internal state, the pattern Enable Search Indexing uses.
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
}

function Enable-AtlasDefenderToggle {
    param($Toggle)

    Import-AtlasModule -Name Atlas.Security
    Set-AtlasDefenderState -State Enable -Silent:$Toggle.Silent
}
