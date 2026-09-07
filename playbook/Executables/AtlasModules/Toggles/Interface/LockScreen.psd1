@{
    Name        = 'LockScreen'
    Description = 'Windows lock screen (policy show or hide). Show verifies the policy values are really gone after removal.'
    Elevation   = 'Admin'
    Script      = 'LockScreen.ps1'
    States      = @(
        @{
            Name          = 'Show'
            StateValue    = 1
            Launcher      = '4. Interface Tweaks\Lock Screen\Show Lock Screen (default).cmd'
            Reboot        = 'None'
            Registry      = @(
                @{ Path = 'HKLM:\SOFTWARE\Policies\Microsoft\Windows\Personalization'; Name = 'NoLockScreen'; Operation = 'Delete' }
                @{ Path = 'HKLM:\SOFTWARE\Policies\Microsoft\Windows\Personalization'; Name = 'NoChangingLockScreen'; Operation = 'Delete' }
            )
            MachineAction = 'Assert-AtlasLockScreenPolicyRemoved'
        }
        @{
            Name       = 'Hide'
            StateValue = 0
            Launcher   = '4. Interface Tweaks\Lock Screen\Hide Lock Screen.cmd'
            Reboot     = 'None'
            Registry   = @(
                @{ Path = 'HKLM:\SOFTWARE\Policies\Microsoft\Windows\Personalization'; Name = 'NoLockScreen'; Type = 'DWord'; Data = 1 }
                @{ Path = 'HKLM:\SOFTWARE\Policies\Microsoft\Windows\Personalization'; Name = 'NoChangingLockScreen'; Type = 'DWord'; Data = 1 }
            )
        }
    )
}
