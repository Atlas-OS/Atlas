@{
    Name        = 'Disable WU Auto-Updates'
    Description = 'Turns off automatic Windows updates through the AutomaticUpdates toggle when you choose that in Atlas Manager. Security updates then install only when you run Windows Update.'
    Option      = 'auto-updates-disable'
    Toggle      = @(
        @{ Name = 'AutomaticUpdates'; State = 'Disable' }
    )
}
