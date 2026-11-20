@{
    Name        = 'Widgets'
    # Enable runs the Edge and WebView helper and opens ms-settings:taskbar only in interactive runs,
    # so update replay never waits on them.
    Description = 'Turns Widgets (News and Interests) on or off.'
    Elevation   = 'Admin'
    Script      = 'Widgets.ps1'
    States      = @(
        @{
            Name                  = 'Disable'
            StateValue            = 0
            Launcher              = '3. General Configuration\Widgets (News and Interests)\Disable Widgets (default).cmd'
            Reboot                = 'RestartExplorer'
            ShellRefreshOperation = 'ExplorerRefresh'
            # Let Windows process the supported device policy through the local GPO.
            # Direct registry writes can be refused even with a TrustedInstaller token.
            Registry              = @(
                @{ Path = 'HKLM:\SOFTWARE\Policies\Microsoft\Dsh'; Name = 'AllowNewsAndInterests'; Type = 'DWord'; Data = 0; UseGroupPolicy = $true }
                # 24H2+ lock-screen widgets and the widgets board itself.
                @{ Path = 'HKLM:\SOFTWARE\Policies\Microsoft\Dsh'; Name = 'DisableWidgetsOnLockScreen'; Type = 'DWord'; Data = 1; AllowOsProtected = $true }
                @{ Path = 'HKLM:\SOFTWARE\Policies\Microsoft\Dsh'; Name = 'DisableWidgetsBoard'; Type = 'DWord'; Data = 1; AllowOsProtected = $true }
            )
        }
        @{
            Name                  = 'Enable'
            StateValue            = 1
            Launcher              = '3. General Configuration\Widgets (News and Interests)\Enable Widgets.cmd'
            Reboot                = 'RestartExplorer'
            ShellRefreshOperation = 'ExplorerRefresh'
            MachineAction         = 'Enable-AtlasWidgetsMachine'
            UserAction            = 'Install-AtlasWidgetsUser'
        }
    )
}
