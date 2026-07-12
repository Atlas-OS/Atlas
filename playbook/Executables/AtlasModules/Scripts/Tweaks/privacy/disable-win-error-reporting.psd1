@{
    Name        = 'Disable Windows Error Reporting'
    Description = 'Disables Windows Error Reporting for privacy and QoL'
    Registry    = @(
        @{ Path = 'HKCU\SOFTWARE\Policies\Microsoft\Windows\Windows Error Reporting'; Name = 'Disabled'; Type = 'DWord'; Data = 1 }
        @{ Path = 'HKLM\SOFTWARE\Policies\Microsoft\Windows\Windows Error Reporting'; Name = 'Disabled'; Type = 'DWord'; Data = 1 }
    )
}
