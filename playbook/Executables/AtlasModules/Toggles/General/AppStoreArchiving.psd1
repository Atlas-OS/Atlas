@{
    Name        = 'AppStoreArchiving'
    Description = 'Microsoft Store automatic app archiving.'
    Elevation   = 'Admin'
    States      = @(
        @{
            Name       = 'Disable'
            StateValue = 0
            Launcher   = '3. General Configuration\Store App Archiving\Disable Store App Archiving (default).cmd'
            Reboot     = 'None'
            Registry   = @(
                @{ Path = 'HKLM:\SOFTWARE\Policies\Microsoft\Windows\Appx'; Name = 'AllowAutomaticAppArchiving'; Type = 'DWord'; Data = 0 }
            )
        }
        @{
            Name       = 'Enable'
            StateValue = 1
            Launcher   = '3. General Configuration\Store App Archiving\Enable Store App Archiving.cmd'
            Reboot     = 'None'
            Registry   = @(
                @{ Path = 'HKLM:\SOFTWARE\Policies\Microsoft\Windows\Appx'; Name = 'AllowAutomaticAppArchiving'; Type = 'DWord'; Data = 1 }
            )
        }
    )
}
