@{
    Name        = 'Disable MSRT telemetry'
    Description = 'Disables MSRT''s (Malicious Software Removal Tool) telemetry features'
    Registry    = @(
        # Disable MSRT telemetry
        @{ Path = 'HKLM:\SOFTWARE\Policies\Microsoft\MRT'; Name = 'DontReportInfectionInformation'; Type = 'DWord'; Data = 1 }
        @{ Path = 'HKLM:\SOFTWARE\Microsoft\RemovalTools\MpGears'; Name = 'HeartbeatTrackingIndex'; Type = 'DWord'; Data = 0 }
        # Legacy REG_MULTI_SZ with empty data
        @{ Path = 'HKLM:\SOFTWARE\Microsoft\RemovalTools\MpGears'; Name = 'SpyNetReportingLocation'; Type = 'MultiString'; Data = @('') }
    )
}
