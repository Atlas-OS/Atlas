@{
    Name        = 'Disable WU Auto-Reboot'
    Description = 'Disables Windows Update from automatically restarting your computer when there''s pending updates.'
    Registry    = @(
        # Make WU not wake up your computer to install updates
        # Seems to be legacy on Windows 11
        # https://admx.help/?Category=Windows_11_2022&Policy=Microsoft.Policies.WindowsUpdate::AUPowerManagement_Title
        @{ Path = 'HKLM:\SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate'; Name = 'AUPowerManagement'; Type = 'DWord'; Data = 0 }
        # Don't reboot with logged in users
        @{ Path = 'HKLM:\SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate\AU'; Name = 'NoAutoRebootWithLoggedOnUsers'; Type = 'DWord'; Data = 1 }
    )
}
