@{
    Name        = 'Disable Automatic Updates Of Speech Data'
    Description = 'Stops Windows downloading speech model updates in the background.'
    Registry    = @(
        @{ Path = 'HKLM\SOFTWARE\Policies\Microsoft\Speech'; Name = 'AllowSpeechModelUpdate'; Type = 'DWord'; Data = 0 }
    )
}
