@{
    Name        = 'Disable Diagnostic Tracing'
    Description = 'Disables diagnostic tracing (system activities, events or errors) for privacy reasons'
    Registry    = @(
        @{ Path = 'HKLM\SYSTEM\CurrentControlSet\Control\Diagnostics\Performance'; Name = 'DisableDiagnosticTracing'; Type = 'DWord'; Data = 1 }
    )
}
