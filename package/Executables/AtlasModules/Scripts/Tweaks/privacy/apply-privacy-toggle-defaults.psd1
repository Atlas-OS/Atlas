@{
    Name        = 'Apply Privacy Toggle Defaults'
    Description = 'Turns off Phone Link, recent-item tracking and web search through their toggles, and records each choice so updates and new accounts keep it.'
    Toggle      = @(
        @{ Name = 'PhoneLink'; State = 'Disable' }
        @{ Name = 'RecentItems'; State = 'Disable' }
        @{ Name = 'WebSearch'; State = 'Disable' }
    )
}
