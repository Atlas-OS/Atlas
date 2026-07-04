@{
    Name          = 'Disable News and Interests'
    Description   = 'Disables News and Interests on the taskbar for privacy (lots of third party connections) and QoL'
    Registry      = @(
        @{ Path = 'HKLM:\SOFTWARE\Policies\Microsoft\Dsh'; Name = 'AllowNewsAndInterests'; Type = 'DWord'; Data = 0 }
        # 24H2+ lock-screen widgets and the widgets board itself.
        @{ Path = 'HKLM:\SOFTWARE\Policies\Microsoft\Dsh'; Name = 'DisableWidgetsOnLockScreen'; Type = 'DWord'; Data = 1 }
        @{ Path = 'HKLM:\SOFTWARE\Policies\Microsoft\Dsh'; Name = 'DisableWidgetsBoard'; Type = 'DWord'; Data = 1 }
        # Keep the taskbar button state consistent with the policy.
        @{ Path = 'HKCU\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\Advanced'; Name = 'TaskbarDa'; Type = 'DWord'; Data = 0 }
    )
    # The engine's fixed key order kills explorer after the registry writes, which is
    # fine for these HKLM policies.
    StopProcesses = @('explorer')
    Run           = @(
        # The engine restarts explorer.exe from the installer's context.
        @{ Exe = 'explorer.exe'; Wait = $false }
    )
}
