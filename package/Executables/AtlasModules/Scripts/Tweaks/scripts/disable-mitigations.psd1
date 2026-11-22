@{
    Name        = 'Disable Mitigations'
    Description = 'Turns off Windows exploit protection mitigations through the Mitigations toggle when you choose that in Atlas Manager.'
    Option      = 'mitigations-disable'
    # The Toggle key keeps a Mitigations launcher choice made since the install on an update.
    Toggle      = @(
        @{ Name = 'Mitigations'; State = 'Disable' }
    )
}
