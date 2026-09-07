@{
    Name        = 'Location'
    Description = 'Location services (lfsvc / MapsBroker) and Find My Device. The Enable prompt to unlock Find My Device is interactive-only so silent/upgrade re-apply never hangs; in silent mode Find My Device is preserved.'
    Elevation   = 'Admin'
    Script      = 'Location.ps1'
    States      = @(
        @{
            Name          = 'Disable'
            StateValue    = 0
            Launcher      = '3. General Configuration\Location\Disable Location (default).cmd'
            Reboot        = 'None'
            MachineAction = 'Disable-AtlasLocation'
            Registry      = @(
                @{ Path = 'HKCU:\Software\Microsoft\Windows\CurrentVersion\CapabilityAccessManager\ConsentStore\location'; Name = 'ShowGlobalPrompts'; Type = 'DWord'; Data = 0 }
            )
        }
        @{
            Name          = 'Enable'
            StateValue    = 1
            Launcher      = '3. General Configuration\Location\Enable Location.cmd'
            Reboot        = 'None'
            MachineAction = 'Enable-AtlasLocation'
            UserAction    = 'Show-AtlasLocationSettings'
            Registry      = @(
                @{ Path = 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\CapabilityAccessManager\ConsentStore\location'; Name = 'Value'; Type = 'String'; Data = 'Allow' }
                @{ Path = 'HKCU:\Software\Microsoft\Windows\CurrentVersion\CapabilityAccessManager\ConsentStore\location'; Name = 'ShowGlobalPrompts'; Operation = 'Delete' }
            )
        }
    )
}
