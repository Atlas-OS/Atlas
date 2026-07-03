@{
    Name        = 'Don''t Show Office Files'
    Description = 'Don''t show Office files in Quick Access (Home)'
    MinBuild    = 22000
    Registry    = @(
        @{ Path = 'HKCU\Software\Microsoft\Windows\CurrentVersion\Explorer'; Name = 'ShowCloudFilesInQuickAccess'; Type = 'DWord'; Data = 0 }
    )
}
