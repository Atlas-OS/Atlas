@{
    Name        = 'Do Not Use Diagnostic Data For Tailored Experiences'
    Description = 'Prevents Windows from using diagnostic data for tailored experiences for privacy, also labeled as "Let Microsoft provide more tailored experiences with relevant tips and recommendations by using your diagnostic data"'
    Registry    = @(
        @{ Path = 'HKCU\SOFTWARE\Microsoft\Windows\CurrentVersion\Privacy'; Name = 'TailoredExperiencesWithDiagnosticDataEnabled'; Type = 'DWord'; Data = 0 }
        @{ Path = 'HKCU\SOFTWARE\Policies\Microsoft\Windows\CloudContent'; Name = 'DisableTailoredExperiencesWithDiagnosticData'; Type = 'DWord'; Data = 1 }
    )
}
