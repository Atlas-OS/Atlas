@{
    Name        = 'Disable Activity Feed'
    Description = 'Disables Activity Feed in Task View for privacy and QoL'
    Registry    = @(
        @{ Path = 'HKLM\SOFTWARE\Policies\Microsoft\Windows\System'; Name = 'EnableActivityFeed'; Type = 'DWord'; Data = 0 }
    )
}
