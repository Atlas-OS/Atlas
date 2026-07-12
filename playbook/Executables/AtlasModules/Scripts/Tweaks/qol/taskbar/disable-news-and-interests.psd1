@{
    Name          = 'Disable News and Interests'
    Description   = 'Disables News and Interests on the taskbar for privacy (lots of third party connections) and QoL'
    Oobe          = $false
    Registry      = @(
        @{ Path = 'HKLM:\SOFTWARE\Policies\Microsoft\Dsh'; Name = 'AllowNewsAndInterests'; Type = 'DWord'; Data = 0 }
        # 24H2+ lock-screen widgets and the widgets board itself.
        @{ Path = 'HKLM:\SOFTWARE\Policies\Microsoft\Dsh'; Name = 'DisableWidgetsOnLockScreen'; Type = 'DWord'; Data = 1 }
        @{ Path = 'HKLM:\SOFTWARE\Policies\Microsoft\Dsh'; Name = 'DisableWidgetsBoard'; Type = 'DWord'; Data = 1 }
        # Keep the taskbar button state consistent with the policy.
        @{ Path = 'HKCU\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\Advanced'; Name = 'TaskbarDa'; Type = 'DWord'; Data = 0 }
    )
    # Reload the exact user's shell only after the separated live-HKCU pass succeeds.
    PostUserRegistryRefresh = 'ExplorerRefresh'
}
