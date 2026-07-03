@{
    Name        = 'Disable Device Health Attestation Monitoring and Reporting'
    Description = 'Disables Device Health Attestation Monitoring and Reporting on startup for privacy'
    Registry    = @(
        @{ Path = 'HKLM\SOFTWARE\Policies\Microsoft\DeviceHealthAttestationService'; Name = 'EnableDeviceHealthAttestationService'; Type = 'DWord'; Data = 0 }
    )
}
