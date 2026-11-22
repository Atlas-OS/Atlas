@{
    Name        = 'Disable LLMNR Protocol'
    Description = 'Turns off Link-Local Multicast Name Resolution (LLMNR), which attackers can abuse to capture credentials on untrusted networks. Home networks often rely on it to find PCs by name, which is why the install doesn''t apply this tweak.'
    Registry    = @(
        # https://admx.help/?Category=Windows_11_2022&Policy=Microsoft.Policies.DNSClient::Turn_Off_Multicast
        @{ Path = 'HKLM\SOFTWARE\Policies\Microsoft\Windows NT\DNSClient'; Name = 'EnableMulticast'; Type = 'DWord'; Data = 0 }
    )
}
