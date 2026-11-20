@{
    Name        = 'Disable Resultant Set of Policy (RSoP) Logging'
    Description = 'Turns off Resultant Set of Policy logging, which records the Group Policy settings applied to the PC and its users.'
    Registry    = @(
        @{ Path = 'HKLM\SOFTWARE\Policies\Microsoft\Windows\System'; Name = 'RSoPLogging'; Type = 'DWord'; Data = 0 }
    )
}
