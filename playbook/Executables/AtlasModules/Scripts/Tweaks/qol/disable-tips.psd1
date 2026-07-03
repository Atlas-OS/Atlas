@{
    Name        = 'Disable Tips'
    Description = 'Disables tips for QoL and privacy'
    Registry    = @(
        # https://admx.help/?Category=Windows_11_2022&Policy=Microsoft.Policies.CloudContent::DisableSoftLanding
        @{ Path = 'HKLM:\SOFTWARE\Policies\Microsoft\Windows\CloudContent'; Name = 'DisableSoftLanding'; Type = 'DWord'; Data = 1 }
    )
}
