@{
    Name        = 'Disable Website Access to Language List'
    Description = 'Stops websites reading your Windows language list, which sites can use to fingerprint you.'
    Registry    = @(
        @{ Path = 'HKCU\Control Panel\International\User Profile'; Name = 'HttpAcceptLanguageOptOut'; Type = 'DWord'; Data = 1 }
    )
}
