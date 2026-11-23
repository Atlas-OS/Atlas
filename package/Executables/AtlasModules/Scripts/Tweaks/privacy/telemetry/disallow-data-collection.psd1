@{
    Name        = 'Disallow Telemetry and Data Collection'
    Description = 'Disables and stops Connected User Experiences and Telemetry (DiagTrack), sets diagnostic data to the lowest level your Windows edition allows, and limits diagnostic logs and crash dumps.'
    Registry    = @(
        @{ Path = 'HKLM\Software\Policies\Microsoft\Windows\DataCollection'; Name = 'AllowTelemetry'; Type = 'DWord'; Data = 0 }
        @{ Path = 'HKLM\Software\Policies\Microsoft\Windows\DataCollection'; Name = 'LimitDiagnosticLogCollection'; Type = 'DWord'; Data = 1 }
        @{ Path = 'HKLM\Software\Policies\Microsoft\Windows\DataCollection'; Name = 'LimitDumpCollection'; Type = 'DWord'; Data = 1 }
    )
    Services    = @(
        @{ Name = 'DiagTrack'; StartupType = 4 }
        @{ Name = 'DiagTrack'; Operation = 'Stop'; AllowMissing = $true }
    )
    Script      = 'disallow-data-collection.ps1'
}
