@{
    Name        = 'Disable Recall Snapshots'
    Description = 'Disables snapshots of Recall (24H2+)'
    Run         = @(
        # Legacy YAML gated this on builds >= 22000 (Windows 11); the policy the
        # AtlasDesktop script sets is harmless on builds without the feature.
        @{ Exe = '{windir}\AtlasDesktop\3. General Configuration\AI Features\Recall\Disable Recall Support (default).cmd'; Args = '/silent'; Wait = $true }
    )
}
