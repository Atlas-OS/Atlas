function Import-AtlasTakeOwnershipContextMenu {
    param($Toggle)

    # The entries span several HKCR file-class keys, so each state ships as a complete
    # .reg snapshot and is applied with reg.exe instead of individual value entries.
    $regFile = switch -CaseSensitive ([string]$Toggle.State) {
        'Disable' { 'remove.reg' }
        'Enable' { 'add.reg' }
        default { throw "TakeOwnership: unsupported state '$($Toggle.State)'." }
    }
    Import-AtlasRegFile -Path (Join-Path -Path $Toggle.ScriptsPath -ChildPath "Registry\TakeOwnership\$regFile")
}
