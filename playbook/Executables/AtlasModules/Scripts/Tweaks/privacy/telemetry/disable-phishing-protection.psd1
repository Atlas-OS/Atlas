@{
    Name        = 'Disable Enhanced Phishing Protection'
    Description = 'Disables SmartScreen Enhanced Phishing Protection, which by default runs in audit mode and silently reports unsafe password-entry events to Microsoft, and on 24H2+ can capture screen content and application memory when triggered. Trade-off: Windows no longer warns when the sign-in password is typed into a known phishing site.'
    Registry    = @(
        # https://learn.microsoft.com/en-us/windows/client-management/mdm/policy-csp-webthreatdefense
        @{ Path = 'HKLM\SOFTWARE\Policies\Microsoft\Windows\WTDS\Components'; Name = 'ServiceEnabled'; Type = 'DWord'; Data = 0 }
        # 24H2+ automatic data collection (content/sound/app-memory capture); pinned off by policy.
        @{ Path = 'HKLM\SOFTWARE\Policies\Microsoft\Windows\WTDS\Components'; Name = 'CaptureThreatWindow'; Type = 'DWord'; Data = 0 }
    )
}
