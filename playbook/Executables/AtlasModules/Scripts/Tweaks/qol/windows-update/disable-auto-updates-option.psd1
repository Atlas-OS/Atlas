@{
    Name        = 'Disable WU Auto-Updates'
    Description = 'Disables Windows Update from automatically updating Windows for QoL, at the cost of security. Split from disable-auto-updates: only this part is gated on the ''auto-updates-disable'' option.'
    Option      = 'auto-updates-disable'
    Run         = @(
        # Disable auto-updates
        @{ Exe = '{windir}\AtlasDesktop\3. General Configuration\Automatic Updates\Disable Automatic Updates (default).cmd'; Args = '/silent'; Wait = $true }
    )
}
