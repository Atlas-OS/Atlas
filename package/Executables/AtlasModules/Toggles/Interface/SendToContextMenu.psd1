@{
    Name          = 'SendToContextMenu'
    Description   = 'Lets you hide or show entries in the Send to menu for your account. With /silent, it applies the Atlas defaults without asking.'
    Elevation     = 'None'
    NoStateRecord = $true
    Script        = 'SendToContextMenu.ps1'
    States        = @(
        @{
            Name     = 'Debloat'
            Launcher = '4. Interface Tweaks\Context Menus\Send To\Debloat Send To Context Menu.cmd'
            Reboot   = 'None'
            Action   = 'Invoke-AtlasSendToContextMenuChooser'
        }
    )
}
