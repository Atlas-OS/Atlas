@{
    Name        = 'EdgeSwipe'
    Description = 'Edge Swipe gesture on touch screens.'
    Elevation   = 'Admin'
    States      = @(
        @{
            Name       = 'Allow'
            StateValue = 1
            Launcher   = '4. Interface Tweaks\Edge Swipe\Allow Edge Swipe (default).cmd'
            Reboot     = 'None'
            Registry   = @(
                @{ Path = 'HKLM:\SOFTWARE\Policies\Microsoft\Windows\EdgeUI'; Name = 'AllowEdgeSwipe'; Operation = 'Delete' }
            )
        }
        @{
            Name       = 'Disallow'
            StateValue = 0
            Launcher   = '4. Interface Tweaks\Edge Swipe\Disallow Edge Swipe.cmd'
            Reboot     = 'None'
            Registry   = @(
                @{ Path = 'HKLM:\SOFTWARE\Policies\Microsoft\Windows\EdgeUI'; Name = 'AllowEdgeSwipe'; Type = 'DWord'; Data = 0 }
            )
        }
    )
}
