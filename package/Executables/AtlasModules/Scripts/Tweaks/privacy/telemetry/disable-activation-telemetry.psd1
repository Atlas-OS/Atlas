@{
    Name        = 'Disable Key Management System Telemetry'
    Description = 'Stops this PC sending KMS client activation data to Microsoft by turning off online AVS validation.'
    Registry    = @(
        # https://admx.help/?Category=Windows_11_2022&Policy=Microsoft.Policies.SoftwareProtectionPlatform::NoAcquireGT
        @{ Path = 'HKLM\SOFTWARE\Policies\Microsoft\Windows NT\CurrentVersion\Software Protection Platform'; Name = 'NoGenTicket'; Type = 'DWord'; Data = 1 }
    )
}
