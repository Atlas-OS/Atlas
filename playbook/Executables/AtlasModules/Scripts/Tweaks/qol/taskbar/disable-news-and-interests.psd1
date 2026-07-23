@{
    Name          = 'Disable News and Interests'
    Description   = 'Disables News and Interests on the taskbar for privacy (lots of third party connections) and QoL'
    Registry      = @(
        @{ Path = 'HKLM:\SOFTWARE\Policies\Microsoft\Dsh'; Name = 'AllowNewsAndInterests'; Type = 'DWord'; Data = 0 }
        # 24H2+ lock-screen widgets and the widgets board itself.
        @{ Path = 'HKLM:\SOFTWARE\Policies\Microsoft\Dsh'; Name = 'DisableWidgetsOnLockScreen'; Type = 'DWord'; Data = 1 }
        @{ Path = 'HKLM:\SOFTWARE\Policies\Microsoft\Dsh'; Name = 'DisableWidgetsBoard'; Type = 'DWord'; Data = 1 }
        # Keep the taskbar button state consistent with the policy.
        # Explorer can leave this per-user key absent or non-writable while its shell
        # state is being rebuilt. Machine policy above is authoritative; this value is
        # only an advisory UI-state synchronization and must not halt installation.
        @{ Path = 'HKCU\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\Advanced'; Name = 'TaskbarDa'; Type = 'DWord'; Data = 0; IgnoreErrors = $true }
    )
    # Reload the exact user's shell only after the separated live-HKCU pass succeeds.
    PostUserRegistryRefresh = 'ExplorerRefresh'
}
