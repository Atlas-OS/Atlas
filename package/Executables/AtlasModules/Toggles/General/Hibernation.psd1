@{
    Name        = 'Hibernation'
    Description = 'Turns hibernation on or off with `powercfg /hibernate`, along with the Hibernate option in the Start power menu.'
    Elevation   = 'Admin'
    Script      = 'Hibernation.ps1'
    States      = @(
        @{
            Name          = 'Disable'
            StateValue    = 0
            Launcher      = '3. General Configuration\Hibernation\Disable Hibernation (default).cmd'
            Reboot        = 'Prompt'
            Registry      = @(
                @{ Path = 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\FlyoutMenuSettings'; Name = 'ShowHibernateOption'; Type = 'DWord'; Data = 0 }
            )
            MachineAction = 'Set-AtlasHibernationPowerState'
        }
        @{
            Name          = 'Enable'
            StateValue    = 1
            Launcher      = '3. General Configuration\Hibernation\Enable Hibernation.cmd'
            Reboot        = 'None'
            Registry      = @(
                @{ Path = 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\FlyoutMenuSettings'; Name = 'ShowHibernateOption'; Type = 'DWord'; Data = 1 }
            )
            MachineAction = 'Set-AtlasHibernationPowerState'
        }
    )
}
