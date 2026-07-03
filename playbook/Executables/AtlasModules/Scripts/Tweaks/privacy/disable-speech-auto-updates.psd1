@{
    Name        = 'Disable Automatic Updates Of Speech Data'
    Description = 'Disables auto-updates of speech data, as it is not commonly used, and it is a potential privacy concern or an overall annoyance'
    Registry    = @(
        @{ Path = 'HKLM\SOFTWARE\Policies\Microsoft\Speech'; Name = 'AllowSpeechModelUpdate'; Type = 'DWord'; Data = 0 }
    )
}
