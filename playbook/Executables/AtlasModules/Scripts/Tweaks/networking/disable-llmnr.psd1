@{
    Name        = 'Disable LLMNR Protocol'
    Description = 'Disable Link-Local Multicast Name Resolution (LLMNR) protocol as it is vulnerable and has been replaced by DNS'
    Registry    = @(
        # https://admx.help/?Category=Windows_11_2022&Policy=Microsoft.Policies.DNSClient::Turn_Off_Multicast
        @{ Path = 'HKLM\SOFTWARE\Policies\Microsoft\Windows NT\DNSClient'; Name = 'EnableMulticast'; Type = 'DWord'; Data = 0 }
    )
}
