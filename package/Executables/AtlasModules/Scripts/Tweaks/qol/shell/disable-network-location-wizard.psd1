@{
    Name        = 'Disable Network Location Wizard'
    Description = 'Turns off the prompt that asks whether the PC should be discoverable when it joins a new network.'
    Registry    = @(
        @{ Path = 'HKLM:\SYSTEM\CurrentControlSet\Control\Network\NewNetworkWindowOff'; Operation = 'AddKey' }
    )
}
