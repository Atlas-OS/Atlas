@{
    Name        = 'Disable WU Nagging'
    Description = 'Hides the Windows Update link that offers the Media Creation Tool for a newer Windows release.'
    Registry    = @(
        # Possibly unused on current Windows. Microsoft does not document this value.
        # Community source: https://www.thewindowsclub.com/disable-windows-creators-update-notice-windows-update
        @{ Path = 'HKLM:\SOFTWARE\Microsoft\WindowsUpdate\UX\Settings'; Name = 'HideMCTLink'; Type = 'DWord'; Data = 1 }
    )
}
