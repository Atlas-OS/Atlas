@{
    Name          = 'Disable News and Interests'
    Description   = 'Turns off Widgets (News and Interests) and its third-party content through the Widgets toggle.'
    # The Widgets toggle owns the machine policy for this setting. Applying its Disable
    # state here records it too, so the install and the AtlasDesktop launcher share one
    # implementation and the recorded state matches the machine.
    Toggle        = @(
        @{ Name = 'Widgets'; State = 'Disable' }
    )
    # The supported device policy controls the entire Widgets experience, including
    # its taskbar entry point; a separate protected TaskbarDa write is unnecessary.
}
