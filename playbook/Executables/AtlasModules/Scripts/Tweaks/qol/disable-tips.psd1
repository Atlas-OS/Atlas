@{
    Name        = 'Disable Tips'
    Description = 'Disables tips for QoL and privacy'
    Registry    = @(
        # Only enforced on Enterprise/Education - kept as an extra layer there. On other
        # editions tips are disabled by the ContentDeliveryManager values in
        # debloat\config-content-delivery (SoftLandingEnabled, SubscribedContent-338389).
        # https://admx.help/?Category=Windows_11_2022&Policy=Microsoft.Policies.CloudContent::DisableSoftLanding
        @{ Path = 'HKLM:\SOFTWARE\Policies\Microsoft\Windows\CloudContent'; Name = 'DisableSoftLanding'; Type = 'DWord'; Data = 1 }
    )
}
