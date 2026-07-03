@{
    Name        = 'Disable Experimentation'
    Description = 'Disallows Microsoft from using your computer as a test for certain features for privacy and stability'
    Registry    = @(
        @{ Path = 'HKLM\SOFTWARE\Microsoft\PolicyManager\default\System\AllowExperimentation'; Name = 'Value'; Type = 'DWord'; Data = 0 }
    )
}
