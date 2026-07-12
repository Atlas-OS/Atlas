@{
    Name        = 'Disallow Telemetry and Data Collection'
    Description = 'Uses supported Windows policy to reduce diagnostic data to the minimum the edition allows and to limit additional diagnostic logs and crash dumps.'
    Registry    = @(
        @{ Path = 'HKLM\Software\Policies\Microsoft\Windows\DataCollection'; Name = 'AllowTelemetry'; Type = 'DWord'; Data = 0 }
        @{ Path = 'HKLM\Software\Policies\Microsoft\Windows\DataCollection'; Name = 'LimitDiagnosticLogCollection'; Type = 'DWord'; Data = 1 }
        @{ Path = 'HKLM\Software\Policies\Microsoft\Windows\DataCollection'; Name = 'LimitDumpCollection'; Type = 'DWord'; Data = 1 }
    )
    Run         = @(
        @{ Exe = '{windir}\System32\WindowsPowerShell\v1.0\powershell.exe'; Args = @('-NoLogo', '-NoProfile', '-NonInteractive', '-ExecutionPolicy', 'Bypass', '-File', '{windir}\AtlasModules\Scripts\Internal\Clear-AtlasTelemetryLogFiles.ps1') }
    )
}
