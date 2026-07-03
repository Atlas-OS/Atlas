@{
    Name        = 'Disable Office Telemetry'
    Description = 'Disables Microsoft Office telemetry for privacy'
    Registry    = @(
        @{ Path = 'HKCU\Software\Policies\Microsoft\office\16.0\common'; Name = 'sendcustomerdata'; Type = 'DWord'; Data = 0 }
        @{ Path = 'HKCU\Software\Policies\Microsoft\office\common\clienttelemetry'; Name = 'sendtelemetry'; Type = 'DWord'; Data = 3 }
        # Customer Experience Program
        @{ Path = 'HKCU\Software\Policies\Microsoft\office\16.0\common'; Name = 'qmenable'; Type = 'DWord'; Data = 0 }
    )
}
