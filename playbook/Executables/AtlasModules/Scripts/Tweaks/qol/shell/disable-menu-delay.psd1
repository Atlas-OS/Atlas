@{
    Name        = 'Disable Menu Hover Delay'
    Description = 'Opens submenus as soon as you hover over them, without the usual delay.'
    Registry    = @(
        @{ Path = 'HKCU\Control Panel\Desktop'; Name = 'MenuShowDelay'; Type = 'String'; Data = '0' }
    )
}
