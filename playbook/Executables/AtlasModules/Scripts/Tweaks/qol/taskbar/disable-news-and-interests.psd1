@{
    Name          = 'Disable News and Interests'
    Description   = 'Disables News and Interests on the taskbar for privacy (lots of third party connections) and QoL'
    Registry      = @(
        @{ Path = 'HKLM:\SOFTWARE\Policies\Microsoft\Windows\Windows Feeds'; Name = 'EnableFeeds'; Type = 'DWord'; Data = 0 }
        @{ Path = 'HKLM:\SOFTWARE\Policies\Microsoft\Dsh'; Name = 'AllowNewsAndInterests'; Type = 'DWord'; Data = 0 }
    )
    # The engine's fixed key order kills explorer after the registry writes, which is
    # fine for these HKLM policies.
    StopProcesses = @('explorer')
    Run           = @(
        # The engine restarts explorer.exe from the installer's context.
        @{ Exe = 'explorer.exe'; Wait = $false }
    )
}
