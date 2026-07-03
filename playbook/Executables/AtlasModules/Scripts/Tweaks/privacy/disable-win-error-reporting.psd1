@{
    Name        = 'Disable Windows Error Reporting'
    Description = 'Disables Windows Error Reporting for privacy and QoL'
    Registry    = @(
        # https://admx.help/?Category=Windows_11_2022&Policy=Microsoft.Policies.InternetCommunicationManagement::PCH_DoNotReport
        @{ Path = 'HKCU\SOFTWARE\Policies\Microsoft\Windows\Windows Error Reporting'; Name = 'Disabled'; Type = 'DWord'; Data = 1 }
        @{ Path = 'HKLM\SOFTWARE\Policies\Microsoft\PCHealth\ErrorReporting'; Name = 'DoReport'; Type = 'DWord'; Data = 0 }
        @{ Path = 'HKLM\SOFTWARE\Policies\Microsoft\Windows\Windows Error Reporting'; Name = 'Disabled'; Type = 'DWord'; Data = 1 }
        @{ Path = 'HKLM\SOFTWARE\Policies\Microsoft\Windows\Windows Error Reporting'; Name = 'DontShowUI'; Type = 'DWord'; Data = 1 }
        @{ Path = 'HKLM\SOFTWARE\Policies\Microsoft\PCHealth\ErrorReporting'; Name = 'ShowUI'; Type = 'DWord'; Data = 0 }
        @{ Path = 'HKLM\SOFTWARE\Policies\Microsoft\Windows\Windows Error Reporting'; Name = 'LoggingDisabled'; Type = 'DWord'; Data = 1 }
        @{ Path = 'HKLM\SOFTWARE\Policies\Microsoft\Windows\Windows Error Reporting'; Name = 'DontSendAdditionalData'; Type = 'DWord'; Data = 1 }
        @{ Path = 'HKLM\Software\Microsoft\Windows\CurrentVersion\Component Based Servicing'; Name = 'DisableWerReporting'; Type = 'DWord'; Data = 1 }
        # Do not send a Windows error report when a generic driver is installed on a device
        @{ Path = 'HKLM\SOFTWARE\Policies\Microsoft\Windows\DeviceInstall\Settings'; Name = 'DisableSendGenericDriverNotFoundToWER'; Type = 'DWord'; Data = 1 }
        # Prevent Windows from sending an error report when a device driver requests additional software during installation
        @{ Path = 'HKLM\SOFTWARE\Policies\Microsoft\Windows\DeviceInstall\Settings'; Name = 'DisableSendRequestAdditionalSoftwareToWER'; Type = 'DWord'; Data = 1 }
    )
}
