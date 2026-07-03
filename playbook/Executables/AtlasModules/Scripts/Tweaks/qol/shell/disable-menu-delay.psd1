@{
    Name        = 'Disable Menu Hover Delay'
    Description = 'Makes hovering over sub-menus in menus instant, instead of having a slight delay on hover'
    Registry    = @(
        @{ Path = 'HKCU\Control Panel\Desktop'; Name = 'MenuShowDelay'; Type = 'String'; Data = '0' }
    )
}
