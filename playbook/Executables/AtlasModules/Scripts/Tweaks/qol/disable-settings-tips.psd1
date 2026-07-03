@{
    Name        = 'Disable Settings Tips'
    Description = 'Disables Settings tips for QoL, as most of the time, they only get in the way'
    Registry    = @(
        @{ Path = 'HKLM:\SOFTWARE\Microsoft\PolicyManager\default\Settings\AllowOnlineTips'; Name = 'value'; Type = 'DWord'; Data = 0 }
        @{ Path = 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\Explorer'; Name = 'AllowOnlineTips'; Type = 'DWord'; Data = 0 }
    )
}
