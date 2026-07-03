@{
    Name        = 'Configure App Permissions'
    Description = 'Configures default app permissions in Settings for the optimal privacy'
    Registry    = @(
        @{ Path = 'HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\CapabilityAccessManager\ConsentStore\appDiagnostics'; Name = 'Value'; Type = 'String'; Data = 'Deny' }
        @{ Path = 'HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\CapabilityAccessManager\ConsentStore\location'; Name = 'Value'; Type = 'String'; Data = 'Deny' }
        @{ Path = 'HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\CapabilityAccessManager\ConsentStore\userAccountInformation'; Name = 'Value'; Type = 'String'; Data = 'Deny' }
    )
}
