@{
    Name        = 'Disable WU Auto-Updates'
    Description = 'Disables Windows Update from automatically updating Windows for QoL, at the cost of security. Split from disable-auto-updates: only this part is gated on the ''auto-updates-disable'' option.'
    Option      = 'auto-updates-disable'
    Toggle      = @(
        @{ Name = 'AutomaticUpdates'; State = 'Disable' }
    )
}
