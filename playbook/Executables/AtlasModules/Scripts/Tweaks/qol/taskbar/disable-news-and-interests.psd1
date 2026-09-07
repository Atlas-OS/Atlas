@{
    Name          = 'Disable News and Interests'
    Description   = 'Disables News and Interests on the taskbar for privacy (lots of third party connections) and QoL'
    # The Widgets toggle owns the machine policy for this setting. Applying its Disable
    # state here records it too, so the install and the AtlasDesktop launcher share one
    # implementation and the recorded state matches the machine.
    Toggle        = @(
        @{ Name = 'Widgets'; State = 'Disable' }
    )
    # The supported device policy controls the entire Widgets experience, including
    # its taskbar entry point; a separate protected TaskbarDa write is unnecessary.
}
