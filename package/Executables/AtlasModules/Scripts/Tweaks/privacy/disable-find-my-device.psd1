@{
    Name        = 'Disable Find My Device'
    Description = 'Turns off Find My Device through its documented policy, so it stays off even if location access is turned back on.'
    Registry    = @(
        # Section 5 of Microsoft's guide to managing connections to its services:
        # https://learn.microsoft.com/windows/privacy/manage-connections-from-windows-operating-system-components-to-microsoft-services
        @{ Path = 'HKLM\SOFTWARE\Policies\Microsoft\FindMyDevice'; Name = 'AllowFindMyDevice'; Type = 'DWord'; Data = 0 }
    )
}
