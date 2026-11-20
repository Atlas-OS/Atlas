@{
    Name        = 'Disable ''Always Read and Scan This Section'''
    Description = 'Turns off "Always read this section aloud" and "Always scan this section" in the Ease of Access Center.'
    Registry    = @(
        @{ Path = 'HKCU\SOFTWARE\Microsoft\Ease of Access'; Name = 'selfscan'; Type = 'DWord'; Data = 0 }
        @{ Path = 'HKCU\SOFTWARE\Microsoft\Ease of Access'; Name = 'selfvoice'; Type = 'DWord'; Data = 0 }
    )
}
