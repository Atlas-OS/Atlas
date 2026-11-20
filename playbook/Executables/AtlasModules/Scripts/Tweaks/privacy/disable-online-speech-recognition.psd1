@{
    Name        = 'Disable Online Speech Recognition'
    Description = 'Turns off online speech recognition, so your voice isn''t sent to Microsoft''s speech service. You can turn it back on in Settings.'
    Registry    = @(
        @{ Path = 'HKCU\SOFTWARE\Microsoft\Speech_OneCore\Settings\OnlineSpeechPrivacy'; Name = 'HasAccepted'; Type = 'DWord'; Data = 0 }
    )
    # The AllowInputPersonalization policy stays unset, so you can turn this back on in Settings.
}
