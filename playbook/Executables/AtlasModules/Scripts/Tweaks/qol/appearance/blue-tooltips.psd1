@{
    Name        = 'Change the Tooltip Color to Blue'
    Description = 'Changes the tooltip color to blue'
    Registry    = @(
        @{ Path = 'HKCU\Control Panel\Colors'; Name = 'InfoWindow'; Type = 'String'; Data = '246 253 255' }
    )
}
