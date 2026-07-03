@{
    Name        = 'Disable WU Nagging'
    Description = 'Disables Windows Update from nagging you in any way possible, e.g. about restarting your computer.'
    Registry    = @(
        # Do not adjust default option to 'Install Updates and Shut Down' in Shut Down Windows dialog box
        # https://admx.help/?Category=Windows_11_2022&Policy=Microsoft.Policies.WindowsUpdate::AUNoUasDefaultPolicy_Mach
        @{ Path = 'HKLM:\SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate\AU'; Name = 'NoAUAsDefaultShutdownOption'; Type = 'DWord'; Data = 1 }
        # Seems to be legacy, but it will be kept anyways https://www.thewindowsclub.com/disable-windows-creators-update-notice-windows-update
        @{ Path = 'HKLM:\SOFTWARE\Microsoft\WindowsUpdate\UX\Settings'; Name = 'HideMCTLink'; Type = 'DWord'; Data = 1 }
    )
}
