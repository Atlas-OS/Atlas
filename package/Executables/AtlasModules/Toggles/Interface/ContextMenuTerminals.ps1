# Companion for the ContextMenuTerminals toggle: imports the .reg file for the chosen
# Terminals context menu. Import-AtlasTerminalsContextMenu runs as Administrator when you run
# a launcher and when an update replays the recorded state.

function Import-AtlasTerminalsContextMenu {
    param($Toggle)

    # The Terminals menu spans dozens of HKCR keys, so each state comes as a complete
    # .reg snapshot and is applied with reg.exe instead of individual value entries.
    $regFile = switch -CaseSensitive ([string]$Toggle.State) {
        'Remove' { 'disabled.reg' }
        'Add' { 'enabled.reg' }
        'AddNoWindowsTerminal' { 'minimal.reg' }
        default { throw "ContextMenuTerminals: unsupported state '$($Toggle.State)'." }
    }
    Import-AtlasRegFile -Path (Join-Path -Path $Toggle.ScriptsPath -ChildPath "Registry\Terminals\$regFile")
}
