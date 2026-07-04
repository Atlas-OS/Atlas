@{
    Name        = 'Disable Click To Do'
    Description = 'Disables the Click To Do AI feature'
    Run         = @(
        @{ Exe = '{windir}\AtlasDesktop\3. General Configuration\AI Features\Click To Do\Disable Click To Do (default).cmd'; Args = '/silent'; Wait = $true }
    )
}
