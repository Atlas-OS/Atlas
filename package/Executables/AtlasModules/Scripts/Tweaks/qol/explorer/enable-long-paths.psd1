@{
    Name        = 'Enable Long Paths'
    Description = 'Lets apps that support it use file paths longer than 260 characters.'
    Registry    = @(
        @{ Path = 'HKLM:\SYSTEM\CurrentControlSet\Control\FileSystem'; Name = 'LongPathsEnabled'; Type = 'DWord'; Data = 1 }
    )
}
