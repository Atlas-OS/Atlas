@{
    Name        = 'Disable Online Speech Recognition'
    Description = 'Disables online speech recognition for privacy purposes'
    Registry    = @(
        @{ Path = 'HKCU\SOFTWARE\Microsoft\Speech_OneCore\Settings\OnlineSpeechPrivacy'; Name = 'HasAccepted'; Type = 'DWord'; Data = 0 }
    )
    # Allow user to enable it in case they need to
    # - !registryValue:
    #   path: 'HKLM\SOFTWARE\Policies\Microsoft\InputPersonalization'
    #   value: 'AllowInputPersonalization'
    #   data: '0'
    #   type: REG_DWORD
}
