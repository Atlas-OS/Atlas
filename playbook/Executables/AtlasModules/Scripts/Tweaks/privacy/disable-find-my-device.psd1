@{
    Name        = 'Disable Find My Device'
    Description = 'Disables the Find My Device location beacon via its documented policy, so it stays off even if a user re-enables location access'
    Registry    = @(
        # https://learn.microsoft.com/en-us/windows/privacy/manage-connections-from-windows-operating-system-components-to-microsoft-services (section 5)
        @{ Path = 'HKLM\SOFTWARE\Policies\Microsoft\FindMyDevice'; Name = 'AllowFindMyDevice'; Type = 'DWord'; Data = 0 }
    )
}
