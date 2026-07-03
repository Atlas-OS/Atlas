@{
    Name        = 'Disable Automatic Store App Archiving'
    Description = 'Disables automatic Store app archiving so that less commonly apps don''t disappear and have to be redownloaded'
    Run         = @(
        @{ Exe = '{windir}\AtlasDesktop\3. General Configuration\Store App Archiving\Disable Store App Archiving (default).cmd'; Args = '/silent'; Wait = $true }
    )
}
