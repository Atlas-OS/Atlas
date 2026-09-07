@{
    Name        = 'SystemRestore'
    Description = 'System Restore policy. Enable also turns on protection for the Windows volume; it does not create a restore point or enable other volumes.'
    Elevation   = 'Admin'
    Script      = 'SystemRestore.ps1'
    States      = @(
        @{
            Name       = 'Disable'
            StateValue = 0
            Launcher   = '3. General Configuration\System Restore\Disable System Restore.cmd'
            Reboot     = 'None'
            Registry   = @(
                @{ Path = 'HKLM:\SOFTWARE\Policies\Microsoft\Windows NT\SystemRestore'; Name = 'DisableSR'; Type = 'DWord'; Data = 1 }
            )
        }
        @{
            Name       = 'Enable'
            MachineAction = 'Enable-AtlasWindowsVolumeProtection'
            StateValue = 1
            Launcher   = '3. General Configuration\System Restore\Enable System Restore (default).cmd'
            Reboot     = 'None'
            Registry   = @(
                @{ Path = 'HKLM:\SOFTWARE\Policies\Microsoft\Windows NT\SystemRestore'; Name = 'DisableSR'; Operation = 'Delete' }
            )
        }
    )
}
