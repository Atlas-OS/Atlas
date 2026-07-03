@{
    Name        = 'Set Taskbar to Align Left'
    Description = 'Sets taskbar to align left instead of centered'
    # Legacy playbook gated this to Windows 11 (builds >= 22000); the value is harmless
    # on Windows 10, whose taskbar is always left-aligned.
    Registry    = @(
        @{ Path = 'HKCU\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced'; Name = 'TaskbarAl'; Type = 'DWord'; Data = 0 }
    )
}
