@{
    Name        = 'Disable Accessibility Tool Shortcut'
    Description = 'Disables the accessibility tool shortcut that launches with Win+Vol, which is also labeled as making touch and tablets easier to use, for QoL'
    Registry    = @(
        @{ Path = 'HKCU\Control Panel\Accessibility\SlateLaunch'; Name = 'LaunchAT'; Type = 'DWord'; Data = 0 }
    )
}
