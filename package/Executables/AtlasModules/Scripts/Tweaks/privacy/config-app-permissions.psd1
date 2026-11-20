@{
    Name        = 'Configure App Permissions'
    Description = 'Denies apps access to your location, account information, app diagnostics and generative AI by default. You can still allow each app in Settings.'
    Registry    = @(
        @{ Path = 'HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\CapabilityAccessManager\ConsentStore\appDiagnostics'; Name = 'Value'; Type = 'String'; Data = 'Deny' }
        @{ Path = 'HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\CapabilityAccessManager\ConsentStore\location'; Name = 'Value'; Type = 'String'; Data = 'Deny'; VerifyWithToggle = @{ Name = 'Location'; State = 1; Type = 'String'; Data = 'Allow' } }
        @{ Path = 'HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\CapabilityAccessManager\ConsentStore\userAccountInformation'; Name = 'Value'; Type = 'String'; Data = 'Deny' }
        # 24H2+ 'Let apps use generative AI' permission. ConsentStore Deny (not the
        # LetAppsAccessGenerativeAI=2 force-deny policy) so users can re-allow per app.
        @{ Path = 'HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\CapabilityAccessManager\ConsentStore\generativeAI'; Name = 'Value'; Type = 'String'; Data = 'Deny'; IgnoreErrors = $true }
    )
}
