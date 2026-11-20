@{
    Name        = 'Disable Diagnostic Tracing'
    Description = 'Turns off performance diagnostic tracing, which records system activity, events and errors.'
    Registry    = @(
        @{ Path = 'HKLM\SYSTEM\CurrentControlSet\Control\Diagnostics\Performance'; Name = 'DisableDiagnosticTracing'; Type = 'DWord'; Data = 1 }
    )
}
