@{
    Name        = 'Disable NVIDIA Control Panel Telemetry'
    Description = 'Disables NVIDIA Control Panel telemetry for privacy'
    Registry    = @(
        @{ Path = 'HKCU\Software\NVIDIA Corporation\NVControlPanel2\Client'; Name = 'OptInOrOutPreference'; Type = 'DWord'; Data = 0 }
    )
}
