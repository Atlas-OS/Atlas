@{
    Name        = 'Apply Privacy Toggle Defaults'
    Description = 'Disables Phone Link, recent-item tracking, and web search through their toggle definitions, recording each applied choice for upgrade and user replay.'
    Toggle      = @(
        @{ Name = 'PhoneLink'; State = 'Disable' }
        @{ Name = 'RecentItems'; State = 'Disable' }
        @{ Name = 'WebSearch'; State = 'Disable' }
    )
}
