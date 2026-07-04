@{
    Name        = 'Disable Recall Snapshots'
    Description = 'Disables snapshots of Recall (24H2+)'
    Run         = @(
        @{ Exe = '{windir}\AtlasDesktop\3. General Configuration\AI Features\Recall\Disable Recall Support (default).cmd'; Args = '/silent'; Wait = $true }
    )
}
