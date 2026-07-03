@{
    Name        = 'Disable Mouse Acceleration'
    Description = 'Disables mouse acceleration (also called ''Enhance Pointer Precision'') for 1:1 mouse movement, which is what most gamers would want'
    Registry    = @(
        @{ Path = 'HKCU\Control Panel\Mouse'; Name = 'MouseSpeed'; Type = 'String'; Data = '0' }
        @{ Path = 'HKCU\Control Panel\Mouse'; Name = 'MouseThreshold1'; Type = 'String'; Data = '0' }
        @{ Path = 'HKCU\Control Panel\Mouse'; Name = 'MouseThreshold2'; Type = 'String'; Data = '0' }
    )
}
