@{
    Name        = 'Do Not Use Diagnostic Data For Tailored Experiences'
    Description = 'Stops Microsoft using your diagnostic data for tailored tips, adverts and recommendations, the "Tailored experiences" setting in Settings.'
    Registry    = @(
        @{ Path = 'HKCU\SOFTWARE\Microsoft\Windows\CurrentVersion\Privacy'; Name = 'TailoredExperiencesWithDiagnosticDataEnabled'; Type = 'DWord'; Data = 0 }
        @{ Path = 'HKCU\SOFTWARE\Policies\Microsoft\Windows\CloudContent'; Name = 'DisableTailoredExperiencesWithDiagnosticData'; Type = 'DWord'; Data = 1 }
    )
}
