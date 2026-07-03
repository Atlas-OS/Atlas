@{
    Name        = 'Disable Website Access to Language List'
    Description = 'Disables websites accessing the Windows language list for the best privacy, as it is a common fingerprinting technique to identify a user by their languages'
    Registry    = @(
        @{ Path = 'HKCU\Control Panel\International\User Profile'; Name = 'HttpAcceptLanguageOptOut'; Type = 'DWord'; Data = 1 }
    )
}
