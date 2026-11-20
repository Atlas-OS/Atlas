@{
    Name        = 'Disable Device Health Attestation Monitoring and Reporting'
    Description = 'Turns off Device Health Attestation monitoring, which reports the PC''s boot security state to a management service at startup.'
    Registry    = @(
        @{ Path = 'HKLM\SOFTWARE\Policies\Microsoft\DeviceHealthAttestationService'; Name = 'EnableDeviceHealthAttestationService'; Type = 'DWord'; Data = 0 }
    )
}
