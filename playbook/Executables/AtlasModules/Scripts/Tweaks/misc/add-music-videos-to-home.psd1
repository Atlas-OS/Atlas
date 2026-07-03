@{
    Name        = 'Add Music & Videos To Home'
    Description  = 'After disabling recent files in Quick Access, Music & Videos disappear from Home. This re-pins them.'
    # Shell "pin to Home" is a COM verb against the running explorer, so it must run in the
    # interactive user's session.
    RunAs       = 'User'
    Script      = 'add-music-videos-to-home.ps1'
}
