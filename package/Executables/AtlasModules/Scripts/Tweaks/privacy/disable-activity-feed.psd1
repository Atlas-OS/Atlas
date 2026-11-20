@{
    Name        = 'Disable Activity Feed'
    Description = 'Turns off the activity feed, so Windows doesn''t keep a timeline of the apps and files you used.'
    Registry    = @(
        @{ Path = 'HKLM\SOFTWARE\Policies\Microsoft\Windows\System'; Name = 'EnableActivityFeed'; Type = 'DWord'; Data = 0 }
    )
}
