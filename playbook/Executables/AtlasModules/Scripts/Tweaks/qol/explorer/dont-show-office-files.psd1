@{
    Name        = 'Don''t Show Office Files'
    Description = 'Don''t show Office files in Quick Access (Home)'
    # Legacy playbook gated this to Windows 11 (builds >= 22000); the value is harmless
    # on Windows 10, which has no cloud files in Quick Access.
    Registry    = @(
        @{ Path = 'HKCU\Software\Microsoft\Windows\CurrentVersion\Explorer'; Name = 'ShowCloudFilesInQuickAccess'; Type = 'DWord'; Data = 0 }
    )
}
