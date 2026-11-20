@{
    Name        = 'AutomaticUpdates'
    Description = 'Turns automatic Windows updates on or off through the AUOptions Windows Update policy.'
    Elevation   = 'Admin'
    States      = @(
        @{
            Name       = 'Disable'
            StateValue = 0
            Launcher   = '3. General Configuration\Automatic Updates\Disable Automatic Updates (default).cmd'
            Reboot     = 'None'
            Registry   = @(
                @{ Path = 'HKLM:\SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate\AU'; Name = 'AUOptions'; Type = 'DWord'; Data = 2 }
            )
        }
        @{
            Name       = 'Enable'
            StateValue = 1
            Launcher   = '3. General Configuration\Automatic Updates\Enable Automatic Updates.cmd'
            Reboot     = 'None'
            Registry   = @(
                @{ Path = 'HKLM:\SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate\AU'; Name = 'AUOptions'; Operation = 'Delete' }
            )
        }
    )
}
