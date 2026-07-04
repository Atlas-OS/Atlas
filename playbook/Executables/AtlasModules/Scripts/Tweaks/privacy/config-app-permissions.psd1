@{
    Name        = 'Configure App Permissions'
    Description = 'Configures default app permissions in Settings for the optimal privacy'
    Registry    = @(
        @{ Path = 'HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\CapabilityAccessManager\ConsentStore\appDiagnostics'; Name = 'Value'; Type = 'String'; Data = 'Deny' }
        @{ Path = 'HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\CapabilityAccessManager\ConsentStore\location'; Name = 'Value'; Type = 'String'; Data = 'Deny' }
        @{ Path = 'HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\CapabilityAccessManager\ConsentStore\userAccountInformation'; Name = 'Value'; Type = 'String'; Data = 'Deny' }
        # 24H2+ 'Let apps use generative AI' permission. ConsentStore Deny (not the
        # LetAppsAccessGenerativeAI=2 force-deny policy) so users can re-allow per app.
        @{ Path = 'HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\CapabilityAccessManager\ConsentStore\generativeAI'; Name = 'Value'; Type = 'String'; Data = 'Deny'; IgnoreErrors = $true }
    )
}
