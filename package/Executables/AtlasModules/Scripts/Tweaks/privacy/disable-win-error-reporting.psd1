@{
    Name        = 'Disable Windows Error Reporting'
    Description = 'Turns off Windows Error Reporting, so crash and error reports aren''t sent to Microsoft.'
    Registry    = @(
        @{ Path = 'HKCU\SOFTWARE\Policies\Microsoft\Windows\Windows Error Reporting'; Name = 'Disabled'; Type = 'DWord'; Data = 1 }
        @{ Path = 'HKLM\SOFTWARE\Policies\Microsoft\Windows\Windows Error Reporting'; Name = 'Disabled'; Type = 'DWord'; Data = 1 }
    )
}
