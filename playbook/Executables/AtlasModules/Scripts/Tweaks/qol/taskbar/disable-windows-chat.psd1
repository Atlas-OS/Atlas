@{
    Name        = 'Disable Windows Chat'
    Description = 'Disables Windows Chat as it''s not commonly used'
    MinBuild    = 22000
    Registry    = @(
        @{ Path = 'HKLM:\SOFTWARE\Policies\Microsoft\Windows\Windows Chat'; Name = 'ChatIcon'; Type = 'DWord'; Data = 3 }
        @{ Path = 'HKCU\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced'; Name = 'TaskbarMn'; Type = 'DWord'; Data = 0 }
    )
}
