@{
    Name        = 'PhoneLink'
    Description = 'Mobile Devices and Phone Link: the CDPSvc service, cross-device resume and the YourPhone app. The settings page is opened only for an interactive enable.'
    Elevation   = 'Admin'
    Script      = 'PhoneLink.ps1'
    States      = @(
        @{
            Name          = 'Disable'
            StateValue    = 0
            Launcher      = '3. General Configuration\Mobile Devices (Phone Link)\Disable Mobile Device Settings (default).cmd'
            Reboot        = 'None'
            Registry      = @(
                @{ Path = 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System'; Name = 'NoConnectedUser'; Type = 'DWord'; Data = 1 }
                @{ Path = 'HKCU:\Software\Microsoft\Windows\CurrentVersion\CrossDeviceResume\Configuration'; Name = 'IsResumeAllowed'; Type = 'DWord'; Data = 0 }
                # Windows 11 25H2 exposes the OneDrive provider through the taskbar Resume
                # switch separately from the original cross-device master value.
                @{ Path = 'HKCU:\Software\Microsoft\Windows\CurrentVersion\CrossDeviceResume\Configuration'; Name = 'IsOneDriveResumeAllowed'; Type = 'DWord'; Data = 0 }
                @{ Path = 'HKCU:\SOFTWARE\Microsoft\PolicyManager\default\Connectivity\DisableCrossDeviceResume'; Name = 'Value'; Type = 'DWord'; Data = 1 }
                @{ Path = 'HKCU:\Software\Microsoft\Windows\CurrentVersion\CDP'; Name = 'NearShareChannelUserAuthzPolicy'; Type = 'DWord'; Data = 0 }
                @{ Path = 'HKCU:\Software\Microsoft\Windows\CurrentVersion\CDP'; Name = 'CdpSessionUserAuthzPolicy'; Type = 'DWord'; Data = 1 }
                @{ Path = 'HKCU:\Software\Microsoft\Windows\CurrentVersion\CDP\SettingsPage'; Name = 'BluetoothLastDisabledNearShare'; Type = 'DWord'; Data = 0 }
            )
            Services      = @(
                @{ Name = 'CDPSvc'; StartupType = 4; AllowMissing = $true }
            )
            MachineAction = 'Disable-AtlasPhoneLinkMachine'
        }
        @{
            Name          = 'Enable'
            StateValue    = 1
            Launcher      = '3. General Configuration\Mobile Devices (Phone Link)\Enable Mobile Device Settings.cmd'
            Reboot        = 'None'
            Registry      = @(
                @{ Path = 'HKCU:\Software\Microsoft\Windows\CurrentVersion\CrossDeviceResume\Configuration'; Name = 'IsResumeAllowed'; Type = 'DWord'; Data = 1 }
                # Windows 11 25H2 exposes the OneDrive provider through the taskbar Resume
                # switch separately from the original cross-device master value.
                @{ Path = 'HKCU:\Software\Microsoft\Windows\CurrentVersion\CrossDeviceResume\Configuration'; Name = 'IsOneDriveResumeAllowed'; Type = 'DWord'; Data = 1 }
                @{ Path = 'HKCU:\SOFTWARE\Microsoft\PolicyManager\default\Connectivity\DisableCrossDeviceResume'; Name = 'Value'; Type = 'DWord'; Data = 0 }
            )
            Services      = @(
                @{ Name = 'CDPSvc'; StartupType = 3 }
            )
            MachineAction = 'Enable-AtlasPhoneLinkMachine'
            UserAction    = 'Enable-AtlasPhoneLinkUser'
        }
    )
}
