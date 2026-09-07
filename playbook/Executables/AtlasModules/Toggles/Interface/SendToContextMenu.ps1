function Invoke-AtlasSendToContextMenuChooser {
    param($Toggle)

    Import-AtlasModule -Name Atlas.Shell
    if ($Toggle.Silent) {
        Set-AtlasSendToContextMenu -DebloatDefaults
    }
    else {
        Set-AtlasSendToContextMenu
    }
}
