# Companion for the TakeOwnership toggle: imports the .reg file that adds or removes Take
# Ownership. Import-AtlasTakeOwnershipContextMenu runs as Administrator when you run a
# launcher and when an update replays the recorded state.

function Import-AtlasTakeOwnershipContextMenu {
    param($Toggle)

    # The entries span several HKCR file-class keys, so each state comes as a complete
    # .reg snapshot and is applied with reg.exe instead of individual value entries.
    $regFile = switch -CaseSensitive ([string]$Toggle.State) {
        'Disable' { 'remove.reg' }
        'Enable' { 'add.reg' }
        default { throw "TakeOwnership: unsupported state '$($Toggle.State)'." }
    }
    Import-AtlasRegFile -Path (Join-Path -Path $Toggle.ScriptsPath -ChildPath "Registry\TakeOwnership\$regFile")
}
