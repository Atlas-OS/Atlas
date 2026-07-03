@{
    Name        = 'Disable Customer Experience Improvement Program'
    Description = 'Disables Customer Experience Improvement Program (CEIP) as it is related to telemetry, for privacy'
    Registry    = @(
        @{ Path = 'HKLM\SOFTWARE\Policies\Microsoft\AppV\CEIP'; Name = 'CEIPEnable'; Type = 'DWord'; Data = 0 }
        @{ Path = 'HKLM\SOFTWARE\Policies\Microsoft\SQMClient\Windows'; Name = 'CEIPEnable'; Type = 'DWord'; Data = 0 }
    )
}
