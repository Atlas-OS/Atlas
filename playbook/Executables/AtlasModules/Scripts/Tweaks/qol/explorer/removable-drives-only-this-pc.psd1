@{
    Name        = 'Show Removable Drives Only in ''This PC'''
    Description = 'Shows removable drives only in ''This PC'', instead of being separate in the Explorer sidebar, for QoL'
    Registry    = @(
        @{ Path = 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\Desktop\NameSpace\DelegateFolders\{F5FB2C77-0E2F-4A16-A381-3E560C68BC83}'; Operation = 'DeleteKey' }
        @{ Path = 'HKLM:\SOFTWARE\WOW6432Node\Microsoft\Windows\CurrentVersion\Explorer\Desktop\NameSpace\DelegateFolders\{F5FB2C77-0E2F-4A16-A381-3E560C68BC83}'; Operation = 'DeleteKey' }
    )
}
