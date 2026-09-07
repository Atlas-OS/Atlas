@{
    Name        = 'HideAppBrowserControl'
    Description = 'Visibility of the App and Browser Control page in Windows Security. Disable hides the page; Enable shows it.'
    Elevation   = 'Admin'
    States      = @(
        @{
            Name       = 'Disable'
            StateValue = 0
            Launcher   = '7. Security\Defender\Hide App and Browser Control\Hide App and Browser Control (default).cmd'
            Reboot     = 'None'
            Registry   = @(
                @{ Path = 'HKLM:\SOFTWARE\Policies\Microsoft\Windows Defender Security Center\App and Browser protection'; Name = 'UILockdown'; Type = 'DWord'; Data = 1 }
            )
        }
        @{
            Name       = 'Enable'
            StateValue = 1
            Launcher   = '7. Security\Defender\Hide App and Browser Control\Show App and Browser Control.cmd'
            Reboot     = 'None'
            Registry   = @(
                @{ Path = 'HKLM:\SOFTWARE\Policies\Microsoft\Windows Defender Security Center\App and Browser protection'; Name = 'UILockdown'; Operation = 'Delete' }
            )
        }
    )
}
