@{
    Name        = 'Disable Resultant Set of Policy (RSoP) Logging'
    Description = 'Disables logging of Group Policy settings (RSoP) for privacy'
    Registry    = @(
        @{ Path = 'HKLM\SOFTWARE\Policies\Microsoft\Windows\System'; Name = 'RSoPLogging'; Type = 'DWord'; Data = 0 }
    )
}
