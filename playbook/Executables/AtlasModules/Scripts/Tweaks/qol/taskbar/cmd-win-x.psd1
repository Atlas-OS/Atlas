@{
    Name        = 'Show Command Prompt on Win+X'
    Description = 'Shows Command Prompt instead of PowerShell on Windows + X, as it is what most users are familiar with'
    Registry    = @(
        @{ Path = 'HKCU\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\Advanced'; Name = 'DontUsePowerShellOnWinX'; Type = 'DWord'; Data = 1 }
    )
}
