@{
    Name        = 'Disable Mouse Acceleration'
    Description = 'Turns off mouse acceleration (Enhance pointer precision), so the pointer moves the same distance for the same mouse movement at any speed.'
    Registry    = @(
        @{ Path = 'HKCU\Control Panel\Mouse'; Name = 'MouseSpeed'; Type = 'String'; Data = '0' }
        @{ Path = 'HKCU\Control Panel\Mouse'; Name = 'MouseThreshold1'; Type = 'String'; Data = '0' }
        @{ Path = 'HKCU\Control Panel\Mouse'; Name = 'MouseThreshold2'; Type = 'String'; Data = '0' }
    )
}
