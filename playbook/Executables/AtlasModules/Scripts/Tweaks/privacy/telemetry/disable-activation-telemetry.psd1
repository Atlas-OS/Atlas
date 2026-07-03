@{
    Name        = 'Disable Key Management System Telemetry'
    Description = 'Turns off KMS client online AVS validation, which prevents from sending data to Microsoft regardless of its activation state, for privacy'
    Registry    = @(
        # https://admx.help/?Category=Windows_11_2022&Policy=Microsoft.Policies.SoftwareProtectionPlatform::NoAcquireGT
        @{ Path = 'HKLM\SOFTWARE\Policies\Microsoft\Windows NT\CurrentVersion\Software Protection Platform'; Name = 'NoGenTicket'; Type = 'DWord'; Data = 1 }
    )
}
