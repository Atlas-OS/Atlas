@{
    Name        = 'Disable Enhanced Phishing Protection'
    Description = 'Turns off Enhanced Phishing Protection in SmartScreen. By default it runs in audit mode, reports unsafe password entry to Microsoft, and can capture screen content and app memory when triggered. Windows then doesn''t warn you when you type your sign-in password into a known phishing site.'
    Registry    = @(
        # https://learn.microsoft.com/windows/client-management/mdm/policy-csp-webthreatdefense
        @{ Path = 'HKLM\SOFTWARE\Policies\Microsoft\Windows\WTDS\Components'; Name = 'ServiceEnabled'; Type = 'DWord'; Data = 0 }
        # 24H2+ automatic data collection (content/sound/app-memory capture); pinned off by policy.
        @{ Path = 'HKLM\SOFTWARE\Policies\Microsoft\Windows\WTDS\Components'; Name = 'CaptureThreatWindow'; Type = 'DWord'; Data = 0 }
    )
}
