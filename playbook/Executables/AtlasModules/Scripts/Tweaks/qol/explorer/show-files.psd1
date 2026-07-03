@{
    Name        = 'Configure Explorer to Show All Files with File Extensions'
    Description = 'Configures Explorer to show all files with file extensions such as system files, hidden files, etc. This is for QoL and also security.'
    Registry    = @(
        @{ Path = 'HKCU\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\Advanced'; Name = 'Hidden'; Type = 'DWord'; Data = 1 }
        @{ Path = 'HKCU\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\Advanced'; Name = 'HideFileExt'; Type = 'DWord'; Data = 0 }
    )
}
