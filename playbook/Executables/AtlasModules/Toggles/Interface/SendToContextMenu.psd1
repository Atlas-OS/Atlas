@{
    Name          = 'SendToContextMenu'
    Description   = 'Hides or shows entries of the Explorer Send To context menu for the current user. Interactive by default; /silent applies the Atlas defaults. Runs in the user''s own session and records no state.'
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
