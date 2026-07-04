@{
    Name        = 'Disable LLMNR Protocol'
    Description = 'Disables Link-Local Multicast Name Resolution (LLMNR), which is being superseded by mDNS and is a known credential-theft vector (LLMNR poisoning) on untrusted networks. Trade-off: plain \\PCNAME resolution on home LANs often relies on LLMNR (mDNS only covers .local), which is why this ships disabled in the manifest.'
    Registry    = @(
        # https://admx.help/?Category=Windows_11_2022&Policy=Microsoft.Policies.DNSClient::Turn_Off_Multicast
        @{ Path = 'HKLM\SOFTWARE\Policies\Microsoft\Windows NT\DNSClient'; Name = 'EnableMulticast'; Type = 'DWord'; Data = 0 }
    )
}
