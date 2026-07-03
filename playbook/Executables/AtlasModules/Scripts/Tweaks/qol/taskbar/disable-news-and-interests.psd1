@{
    Name          = 'Disable News and Interests'
    Description   = 'Disables News and Interests on the taskbar for privacy (lots of third party connections) and QoL'
    Registry      = @(
        @{ Path = 'HKLM:\SOFTWARE\Policies\Microsoft\Windows\Windows Feeds'; Name = 'EnableFeeds'; Type = 'DWord'; Data = 0 }
        @{ Path = 'HKLM:\SOFTWARE\Policies\Microsoft\Dsh'; Name = 'AllowNewsAndInterests'; Type = 'DWord'; Data = 0 }
    )
    # The legacy playbook killed explorer before the registry writes; the engine's fixed
    # key order kills it afterwards, which is equivalent for these HKLM policies.
    StopProcesses = @('explorer')
    Run           = @(
        # Legacy action ran explorer.exe as 'currentUser'; the engine restarts it from
        # the installer's context instead.
        @{ Exe = 'explorer.exe'; Wait = $false }
    )
}
