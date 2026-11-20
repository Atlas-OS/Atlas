@{
    Name        = 'Disable Touch Visual Feedback'
    Description = 'Turns off the visual feedback Windows shows where you touch the screen.'
    Registry    = @(
        @{ Path = 'HKCU\Control Panel\Cursors'; Name = 'GestureVisualization'; Type = 'DWord'; Data = 0 }
        @{ Path = 'HKCU\Control Panel\Cursors'; Name = 'ContactVisualization'; Type = 'DWord'; Data = 0 }
    )
}
