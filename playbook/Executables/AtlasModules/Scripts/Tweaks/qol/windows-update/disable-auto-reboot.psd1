@{
    Name        = 'Disable WU Auto-Reboot'
    Description = 'Disables Windows Update from automatically restarting your computer when there''s pending updates.'
    Registry    = @(
        # Make WU not wake up your computer to install updates. This is an AU-scoped
        # policy - it must live under the \AU subkey or it is never read.
        # https://admx.help/?Category=Windows_11_2022&Policy=Microsoft.Policies.WindowsUpdate::AUPowerManagement_Title
        @{ Path = 'HKLM:\SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate\AU'; Name = 'AUPowerManagement'; Type = 'DWord'; Data = 0 }
        # Don't reboot with logged in users. Only consulted for Automatic Updates
        # scheduled installs (AUOptions = 4), so it's belt-and-braces here.
        @{ Path = 'HKLM:\SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate\AU'; Name = 'NoAutoRebootWithLoggedOnUsers'; Type = 'DWord'; Data = 1 }
    )
}
