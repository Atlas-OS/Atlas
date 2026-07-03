@{
    Name        = 'Enable Long Paths'
    Description = 'Disables the default path length limit.'
    Registry    = @(
        @{ Path = 'HKLM:\SYSTEM\CurrentControlSet\Control\FileSystem'; Name = 'LongPathsEnabled'; Type = 'DWord'; Data = 1 }
    )
}
