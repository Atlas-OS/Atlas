@{
    Name        = 'Disable File Explorer Home'
    Description = 'Removes Home from File Explorer and opens File Explorer to This PC by default'
    Registry    = @(
        @{ Path = 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\Desktop\NameSpace\{f874310e-b6b7-47dc-bc84-b9e6b38f5903}'; Operation = 'DeleteKey' }
        @{ Path = 'HKCU\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced'; Name = 'LaunchTo'; Type = 'DWord'; Data = 1 }
    )
}
