@{
    Name        = 'Disable AutoRun'
    Description = 'Disables AutoRun, also known as AutoPlay, for optimal QoL'
    Registry    = @(
        @{ Path = 'HKCU\Software\Microsoft\Windows\CurrentVersion\Explorer\AutoplayHandlers'; Name = 'DisableAutoplay'; Type = 'DWord'; Data = 1 }
        @{ Path = 'HKCU\Software\Microsoft\Windows\CurrentVersion\Explorer\AutoplayHandlers\EventHandlersDefaultSelection\CameraAlternate'; Name = 'MSTakeNoAction'; Type = 'None' }
        @{ Path = 'HKCU\Software\Microsoft\Windows\CurrentVersion\Explorer\AutoplayHandlers\EventHandlersDefaultSelection\StorageOnArrival'; Name = 'MSTakeNoAction'; Type = 'None' }
        @{ Path = 'HKCU\Software\Microsoft\Windows\CurrentVersion\Explorer\AutoplayHandlers\UserChosenExecuteHandlers\CameraAlternate\ShowPicturesOnArrival'; Name = 'MSTakeNoAction'; Type = 'None' }
        @{ Path = 'HKCU\Software\Microsoft\Windows\CurrentVersion\Explorer\AutoplayHandlers\UserChosenExecuteHandlers\StorageOnArrival'; Name = 'MSTakeNoAction'; Type = 'None' }
    )
}
