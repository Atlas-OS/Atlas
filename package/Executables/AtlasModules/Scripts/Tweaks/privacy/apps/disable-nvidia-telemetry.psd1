@{
    Name        = 'Disable NVIDIA Control Panel Telemetry'
    Description = 'Opts out of NVIDIA Control Panel telemetry.'
    Registry    = @(
        @{ Path = 'HKCU\Software\NVIDIA Corporation\NVControlPanel2\Client'; Name = 'OptInOrOutPreference'; Type = 'DWord'; Data = 0 }
    )
}
