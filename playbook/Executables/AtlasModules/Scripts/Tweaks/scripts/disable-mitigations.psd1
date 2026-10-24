@{
    Name        = 'Disable Mitigations'
    Description = 'Disables Windows exploit-protection mitigations when the user selected the option.'
    Option      = 'mitigations-disable'
    # The Toggle key keeps a Mitigations launcher choice made since the install on an update.
    Toggle      = @(
        @{ Name = 'Mitigations'; State = 'Disable' }
    )
}
