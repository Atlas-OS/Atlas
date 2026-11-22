@{
    Name        = 'Force Close Applications On Session End'
    Description = 'Closes all apps without asking you to save your work when you restart, shut down or sign out.'
    # Listed under Disabled in tweaks.manifest.psd1, which records why.
    Registry    = @(
        @{ Path = 'HKCU\Control Panel\Desktop'; Name = 'AutoEndTasks'; Type = 'String'; Data = '1' }
    )
}
