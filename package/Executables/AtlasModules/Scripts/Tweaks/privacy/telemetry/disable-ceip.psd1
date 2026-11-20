@{
    Name        = 'Disable Customer Experience Improvement Program'
    Description = 'Turns off the Customer Experience Improvement Program for Windows and App-V, which sends usage data to Microsoft.'
    Registry    = @(
        @{ Path = 'HKLM\SOFTWARE\Policies\Microsoft\AppV\CEIP'; Name = 'CEIPEnable'; Type = 'DWord'; Data = 0 }
        @{ Path = 'HKLM\SOFTWARE\Policies\Microsoft\SQMClient\Windows'; Name = 'CEIPEnable'; Type = 'DWord'; Data = 0 }
    )
}
