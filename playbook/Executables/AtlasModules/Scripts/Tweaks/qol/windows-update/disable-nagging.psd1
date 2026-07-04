@{
    Name        = 'Disable WU Nagging'
    Description = 'Disables Windows Update from nagging you in any way possible, e.g. about restarting your computer.'
    Registry    = @(
        # Seems to be legacy, but it will be kept anyways https://www.thewindowsclub.com/disable-windows-creators-update-notice-windows-update
        @{ Path = 'HKLM:\SOFTWARE\Microsoft\WindowsUpdate\UX\Settings'; Name = 'HideMCTLink'; Type = 'DWord'; Data = 1 }
    )
}
