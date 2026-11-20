@{
    Name        = 'Disable Tips'
    Description = 'Turns off Windows tips through the CloudContent policy, which Enterprise and Education editions enforce.'
    Registry    = @(
        # Only Enterprise and Education enforce this, so it's an extra layer there. On other
        # editions tips are disabled by the ContentDeliveryManager values in
        # debloat\config-content-delivery (SoftLandingEnabled, SubscribedContent-338389).
        # https://admx.help/?Category=Windows_11_2022&Policy=Microsoft.Policies.CloudContent::DisableSoftLanding
        @{ Path = 'HKLM:\SOFTWARE\Policies\Microsoft\Windows\CloudContent'; Name = 'DisableSoftLanding'; Type = 'DWord'; Data = 1 }
    )
}
