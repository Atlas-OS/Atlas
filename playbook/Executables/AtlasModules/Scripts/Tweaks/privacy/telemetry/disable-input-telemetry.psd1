@{
    Name        = 'Disable Input Telemetry'
    Description = 'Disables text, ink and handwriting telemetry for privacy'
    Registry    = @(
        @{ Path = 'HKCU\SOFTWARE\Microsoft\InputPersonalization'; Name = 'RestrictImplicitInkCollection'; Type = 'DWord'; Data = 1 }
        @{ Path = 'HKCU\SOFTWARE\Microsoft\InputPersonalization'; Name = 'RestrictImplicitTextCollection'; Type = 'DWord'; Data = 1 }
        @{ Path = 'HKCU\SOFTWARE\Microsoft\InputPersonalization\TrainedDataStore'; Name = 'HarvestContacts'; Type = 'DWord'; Data = 0 }
        @{ Path = 'HKCU\SOFTWARE\Microsoft\Personalization\Settings'; Name = 'AcceptedPrivacyPolicy'; Type = 'DWord'; Data = 0 }
        @{ Path = 'HKLM\SOFTWARE\Policies\Microsoft\Windows\TabletPC'; Name = 'PreventHandwritingDataSharing'; Type = 'DWord'; Data = 1 }
        @{ Path = 'HKLM\SOFTWARE\Policies\Microsoft\Windows\HandwritingErrorReports'; Name = 'PreventHandwritingErrorReports'; Type = 'DWord'; Data = 1 }
        # Disable typing insights
        @{ Path = 'HKCU\SOFTWARE\Microsoft\Input\Settings'; Name = 'InsightsEnabled'; Type = 'DWord'; Data = 0 }
        # Disable improve inking and typing recognition
        @{ Path = 'HKCU\SOFTWARE\Microsoft\Input\TIPC'; Name = 'Enabled'; Type = 'DWord'; Data = 0 }
        @{ Path = 'HKLM\SOFTWARE\Microsoft\Input\TIPC'; Name = 'Enabled'; Type = 'DWord'; Data = 0 }
    )
}
