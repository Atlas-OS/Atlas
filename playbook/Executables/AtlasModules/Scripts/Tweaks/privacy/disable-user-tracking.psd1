@{
    Name        = 'Disable Most Frequently Used Applications'
    Description = 'Disables the most frequently used applications in the start menu for privacy'
    Registry    = @(
        @{ Path = 'HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\Explorer'; Name = 'NoInstrumentation'; Type = 'DWord'; Data = 1 }
    )
}
