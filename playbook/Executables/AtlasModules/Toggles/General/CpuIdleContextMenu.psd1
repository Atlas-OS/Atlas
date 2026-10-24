@{
    Name        = 'CpuIdleContextMenu'
    Description = 'CPU Idle desktop context menu (HKCR DesktopBackground shell entry). The Command values run the CPU Idle launchers interactively, so they can ask for administrator permission, and are stored as REG_SZ with %windir% intentionally left unexpanded.'
    Elevation   = 'Admin'
    States      = @(
        @{
            Name       = 'Enable'
            StateValue = 1
            Launcher   = '3. General Configuration\CPU Idle\Desktop Context Menu\Add Idle Toggle in Desktop Context Menu.cmd'
            Reboot     = 'None'
            Registry   = @(
                @{ Path = 'HKCR\DesktopBackground\Shell\CpuIdle'; Name = 'Icon'; Type = 'String'; Data = 'powercpl.dll' }
                @{ Path = 'HKCR\DesktopBackground\Shell\CpuIdle'; Name = 'SubCommands'; Type = 'String'; Data = '' }
                @{ Path = 'HKCR\DesktopBackground\Shell\CpuIdle'; Name = 'Position'; Type = 'String'; Data = 'Bottom' }
                @{ Path = 'HKCR\DesktopBackground\Shell\CpuIdle'; Name = 'MUIVerb'; Type = 'String'; Data = 'CPU Idle' }
                @{ Path = 'HKCR\DesktopBackground\Shell\CpuIdle\Shell\Disable Idle'; Name = 'MUIVerb'; Type = 'String'; Data = 'Disable Idle' }
                @{ Path = 'HKCR\DesktopBackground\Shell\CpuIdle\Shell\Disable Idle'; Name = 'Icon'; Type = 'String'; Data = 'powercpl.dll' }
                @{ Path = 'HKCR\DesktopBackground\Shell\CpuIdle\Shell\Disable Idle'; Name = 'HasLUAShield'; Type = 'String'; Data = '' }
                @{ Path = 'HKCR\DesktopBackground\Shell\CpuIdle\Shell\Disable Idle\Command'; Name = ''; Type = 'String'; Data = 'cmd /c ""%windir%\AtlasDesktop\3. General Configuration\CPU Idle\Disable Idle.cmd""' }
                @{ Path = 'HKCR\DesktopBackground\Shell\CpuIdle\Shell\Disable Idle\Command'; Name = 'Icon'; Type = 'String'; Data = 'powercpl.dll' }
                @{ Path = 'HKCR\DesktopBackground\Shell\CpuIdle\Shell\Enable Idle'; Name = 'MUIVerb'; Type = 'String'; Data = 'Enable Idle' }
                @{ Path = 'HKCR\DesktopBackground\Shell\CpuIdle\Shell\Enable Idle'; Name = 'HasLUAShield'; Type = 'String'; Data = '' }
                @{ Path = 'HKCR\DesktopBackground\Shell\CpuIdle\Shell\Enable Idle\Command'; Name = ''; Type = 'String'; Data = 'cmd /c ""%windir%\AtlasDesktop\3. General Configuration\CPU Idle\Enable Idle (default).cmd""' }
            )
        }
        @{
            Name       = 'Disable'
            StateValue = 0
            Launcher   = '3. General Configuration\CPU Idle\Desktop Context Menu\Remove Idle Toggle in Desktop Context Menu (default).cmd'
            Reboot     = 'None'
            Registry   = @(
                @{ Path = 'HKCR\DesktopBackground\Shell\CpuIdle'; Operation = 'DeleteKey' }
            )
        }
    )
}
