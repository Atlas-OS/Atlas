@{
    Name        = 'Never Use Tablet Mode'
    Description = 'Makes Windows never use tablet mode for QoL'
    Registry    = @(
        @{ Path = 'HKCU\SOFTWARE\Microsoft\Windows\CurrentVersion\ImmersiveShell'; Name = 'SignInMode'; Type = 'DWord'; Data = 1 }
    )
}
