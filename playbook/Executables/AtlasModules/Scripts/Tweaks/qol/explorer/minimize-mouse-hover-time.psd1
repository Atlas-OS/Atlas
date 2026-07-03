@{
    Name        = 'Minimize Mouse Hover Time for Item Info'
    Description = 'Minimizes mouse hover time (from 400 ms to 20 ms) for hovering over files or folders mostly in File Explorer, so that you can instantly see information for QoL'
    Registry    = @(
        @{ Path = 'HKCU\Control Panel\Desktop'; Name = 'MouseHoverTime'; Type = 'String'; Data = '20' }
    )
}
