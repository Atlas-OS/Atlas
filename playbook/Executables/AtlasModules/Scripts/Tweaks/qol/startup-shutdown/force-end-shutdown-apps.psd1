@{
    Name        = 'Force Close Applications On Session End'
    Description = 'Forcefully closes all applications on restart, shut down, or sign out of Windows, instead of prompting the user to save everything first'
    # NOTE: disabled (commented out) in the legacy tweaks.yml - "It confused people".
    # Keep it commented out in the tweak manifest.
    Registry    = @(
        @{ Path = 'HKCU\Control Panel\Desktop'; Name = 'AutoEndTasks'; Type = 'String'; Data = '1' }
    )
}
