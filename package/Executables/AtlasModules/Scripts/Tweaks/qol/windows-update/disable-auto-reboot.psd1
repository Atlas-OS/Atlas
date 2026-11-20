@{
    Name        = 'Disable WU Auto-Reboot'
    Description = 'Stops Windows Update restarting the PC while someone is signed in, and waking it to install updates.'
    Registry    = @(
        # Stop Windows Update waking the PC to install updates. This is an AU-scoped
        # policy: it must live under the \AU subkey or it is never read.
        # https://admx.help/?Category=Windows_11_2022&Policy=Microsoft.Policies.WindowsUpdate::AUPowerManagement_Title
        @{ Path = 'HKLM:\SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate\AU'; Name = 'AUPowerManagement'; Type = 'DWord'; Data = 0 }
        # Don't restart while users are signed in. Only consulted for Automatic Updates
        # scheduled installs (AUOptions = 4), so it's belt-and-braces here.
        @{ Path = 'HKLM:\SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate\AU'; Name = 'NoAutoRebootWithLoggedOnUsers'; Type = 'DWord'; Data = 1 }
    )
}
