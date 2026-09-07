@{
    Name        = 'PauseUpdates'
    Description = 'Pause Windows Updates through the WindowsUpdate UX and UpdatePolicy pause dates. Enable pauses updates; Disable unpauses them. Enable also records a days value under the AtlasOS\Services key, which some UI reads.'
    Elevation   = 'Admin'
    Warning     = 'Changes Windows Update policies. While updates are paused, security and driver updates do not install until you unpause them.'
    States      = @(
        @{
            Name       = 'Enable'
            StateValue = 1
            Launcher   = '3. General Configuration\Pause Updates\Pause Windows Updates.cmd'
            Reboot     = 'None'
            Registry   = @(
                @{ Path = 'HKLM:\SOFTWARE\AtlasOS\Services\PauseUpdates'; Name = 'days'; Type = 'DWord'; Data = 356000 }
                @{ Path = 'HKLM:\SOFTWARE\Microsoft\WindowsUpdate\UpdatePolicy\Settings'; Name = 'PausedFeatureStatus'; Type = 'DWord'; Data = 1 }
                @{ Path = 'HKLM:\SOFTWARE\Microsoft\WindowsUpdate\UpdatePolicy\Settings'; Name = 'PausedQualityStatus'; Type = 'DWord'; Data = 1 }
                @{ Path = 'HKLM:\SOFTWARE\Microsoft\WindowsUpdate\UX\Settings'; Name = 'FlightSettingsMaxPauseDays'; Type = 'DWord'; Data = 356000 }
                @{ Path = 'HKLM:\SOFTWARE\Microsoft\WindowsUpdate\UX\Settings'; Name = 'PauseFeatureUpdatesStartTime'; Type = 'String'; Data = '2001-10-25T10:03:37Z' }
                @{ Path = 'HKLM:\SOFTWARE\Microsoft\WindowsUpdate\UX\Settings'; Name = 'PauseQualityUpdatesStartTime'; Type = 'String'; Data = '2001-10-25T10:03:37Z' }
                @{ Path = 'HKLM:\SOFTWARE\Microsoft\WindowsUpdate\UX\Settings'; Name = 'PauseUpdatesStartTime'; Type = 'String'; Data = '2001-10-25T10:03:37Z' }
                @{ Path = 'HKLM:\SOFTWARE\Microsoft\WindowsUpdate\UX\Settings'; Name = 'PauseFeatureUpdatesEndTime'; Type = 'String'; Data = '3000-12-31T14:03:37Z' }
                @{ Path = 'HKLM:\SOFTWARE\Microsoft\WindowsUpdate\UX\Settings'; Name = 'PauseQualityUpdatesEndTime'; Type = 'String'; Data = '3000-12-31T14:03:37Z' }
                @{ Path = 'HKLM:\SOFTWARE\Microsoft\WindowsUpdate\UX\Settings'; Name = 'PauseUpdatesExpiryTime'; Type = 'String'; Data = '3000-12-31T14:03:37Z' }
                @{ Path = 'HKLM:\SOFTWARE\Microsoft\WindowsUpdate\UX\Settings'; Name = 'HideMCTLink'; Type = 'DWord'; Data = 1 }
                @{ Path = 'HKLM:\SOFTWARE\Microsoft\WindowsUpdate\UX\Settings'; Name = 'RestartNotificationsAllowed2'; Type = 'DWord'; Data = 0 }
                @{ Path = 'HKLM:\SYSTEM\Setup\UpgradeNotification'; Name = 'UpgradeAvailable'; Type = 'DWord'; Data = 0 }
            )
        }
        @{
            Name       = 'Disable'
            StateValue = 0
            Launcher   = '3. General Configuration\Pause Updates\Unpause Windows Updates.cmd'
            Reboot     = 'None'
            Registry   = @(
                @{ Path = 'HKLM:\SOFTWARE\AtlasOS\Services\PauseUpdates'; Name = 'days'; Type = 'DWord'; Data = 0 }
                @{ Path = 'HKLM:\SOFTWARE\Microsoft\WindowsUpdate\UpdatePolicy\Settings'; Name = 'PausedFeatureStatus'; Type = 'DWord'; Data = 0 }
                @{ Path = 'HKLM:\SOFTWARE\Microsoft\WindowsUpdate\UpdatePolicy\Settings'; Name = 'PausedQualityStatus'; Type = 'DWord'; Data = 0 }
                @{ Path = 'HKLM:\SOFTWARE\Microsoft\WindowsUpdate\UX\Settings'; Name = 'PauseFeatureUpdatesStartTime'; Operation = 'Delete' }
                @{ Path = 'HKLM:\SOFTWARE\Microsoft\WindowsUpdate\UX\Settings'; Name = 'PauseFeatureUpdatesEndTime'; Operation = 'Delete' }
                @{ Path = 'HKLM:\SOFTWARE\Microsoft\WindowsUpdate\UX\Settings'; Name = 'PauseQualityUpdatesStartTime'; Operation = 'Delete' }
                @{ Path = 'HKLM:\SOFTWARE\Microsoft\WindowsUpdate\UX\Settings'; Name = 'PauseQualityUpdatesEndTime'; Operation = 'Delete' }
                @{ Path = 'HKLM:\SOFTWARE\Microsoft\WindowsUpdate\UX\Settings'; Name = 'PauseUpdatesStartTime'; Operation = 'Delete' }
                @{ Path = 'HKLM:\SOFTWARE\Microsoft\WindowsUpdate\UX\Settings'; Name = 'PauseUpdatesExpiryTime'; Operation = 'Delete' }
                @{ Path = 'HKLM:\SOFTWARE\Microsoft\WindowsUpdate\UX\Settings'; Name = 'PausedFeatureStatus'; Operation = 'Delete' }
                @{ Path = 'HKLM:\SOFTWARE\Microsoft\WindowsUpdate\UX\Settings'; Name = 'PausedQualityStatus'; Operation = 'Delete' }
                @{ Path = 'HKLM:\SOFTWARE\Microsoft\WindowsUpdate\UX\Settings'; Name = 'FlightSettingsMaxPauseDays'; Operation = 'Delete' }
                @{ Path = 'HKLM:\SOFTWARE\Microsoft\WindowsUpdate\UX\Settings'; Name = 'HideMCTLink'; Operation = 'Delete' }
                @{ Path = 'HKLM:\SOFTWARE\Microsoft\WindowsUpdate\UX\Settings'; Name = 'RestartNotificationsAllowed2'; Operation = 'Delete' }
                @{ Path = 'HKLM:\SYSTEM\Setup\UpgradeNotification'; Name = 'UpgradeAvailable'; Operation = 'Delete' }
            )
        }
    )
}
