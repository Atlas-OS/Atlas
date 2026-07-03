@{
    Name        = 'Disable Network Location Wizard'
    Description = 'Disables the Network Location Wizard, which is the pop-up about your network being discoverable'
    Registry    = @(
        @{ Path = 'HKLM:\SYSTEM\CurrentControlSet\Control\Network\NewNetworkWindowOff'; Operation = 'AddKey' }
    )
}
