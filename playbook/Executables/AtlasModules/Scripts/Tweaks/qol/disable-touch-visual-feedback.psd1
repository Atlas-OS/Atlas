@{
    Name        = 'Disable Touch Visual Feedback'
    Description = 'Disables touch visual feedback for QoL'
    Registry    = @(
        @{ Path = 'HKCU\Control Panel\Cursors'; Name = 'GestureVisualization'; Type = 'DWord'; Data = 0 }
        @{ Path = 'HKCU\Control Panel\Cursors'; Name = 'ContactVisualization'; Type = 'DWord'; Data = 0 }
    )
}
