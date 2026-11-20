@{
    Name        = 'Disallow Telemetry and Data Collection'
    Description = 'Sets diagnostic data to the minimum your edition of Windows allows through supported policy, and limits extra diagnostic logs and crash dumps.'
    Registry    = @(
        @{ Path = 'HKLM\Software\Policies\Microsoft\Windows\DataCollection'; Name = 'AllowTelemetry'; Type = 'DWord'; Data = 0 }
        @{ Path = 'HKLM\Software\Policies\Microsoft\Windows\DataCollection'; Name = 'LimitDiagnosticLogCollection'; Type = 'DWord'; Data = 1 }
        @{ Path = 'HKLM\Software\Policies\Microsoft\Windows\DataCollection'; Name = 'LimitDumpCollection'; Type = 'DWord'; Data = 1 }
    )
    Script      = 'disallow-data-collection.ps1'
}
