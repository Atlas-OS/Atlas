@{
    Name        = 'Disable Click To Do'
    Description = 'Disables the Click To Do AI feature'
    Run         = @(
        # Legacy YAML gated this on builds >= 22000 (Windows 11); the policy the
        # AtlasDesktop script sets is harmless on builds without the feature.
        @{ Exe = '{windir}\AtlasDesktop\3. General Configuration\AI Features\Click To Do\Disable Click To Do (default).cmd'; Args = '/silent'; Wait = $true }
    )
}
