@{
    Name        = 'Disable ''Always Read and Scan This Section'''
    Description = 'Disables ''Always Read and Scan This Section'' in Control Panel for QoL'
    Registry    = @(
        @{ Path = 'HKCU\SOFTWARE\Microsoft\Ease of Access'; Name = 'selfscan'; Type = 'DWord'; Data = 0 }
        @{ Path = 'HKCU\SOFTWARE\Microsoft\Ease of Access'; Name = 'selfvoice'; Type = 'DWord'; Data = 0 }
    )
}
