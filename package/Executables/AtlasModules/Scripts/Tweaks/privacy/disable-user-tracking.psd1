@{
    Name        = 'Disable Most Frequently Used Applications'
    Description = 'Stops Windows tracking how often you use programs, so Start doesn''t list your most used apps.'
    Registry    = @(
        @{ Path = 'HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\Explorer'; Name = 'NoInstrumentation'; Type = 'DWord'; Data = 1 }
    )
}
