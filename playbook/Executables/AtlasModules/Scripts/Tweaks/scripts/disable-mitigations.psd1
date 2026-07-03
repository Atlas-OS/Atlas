@{
    Name        = 'Disable Mitigations'
    Description  = 'Disables Windows exploit-protection mitigations when the user selected the option.'
    Option      = 'mitigations-disable'
    Run         = @(
        @{ Exe = '{windir}\AtlasDesktop\7. Security\Mitigations\Disable All Mitigations.cmd'; Args = '/silent' }
    )
}
