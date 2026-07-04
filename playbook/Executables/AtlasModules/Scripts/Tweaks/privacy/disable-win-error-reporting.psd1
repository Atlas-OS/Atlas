@{
    Name        = 'Disable Windows Error Reporting'
    Description = 'Disables Windows Error Reporting for privacy and QoL'
    Registry    = @(
        @{ Path = 'HKCU\SOFTWARE\Policies\Microsoft\Windows\Windows Error Reporting'; Name = 'Disabled'; Type = 'DWord'; Data = 1 }
        @{ Path = 'HKLM\SOFTWARE\Policies\Microsoft\Windows\Windows Error Reporting'; Name = 'Disabled'; Type = 'DWord'; Data = 1 }
        @{ Path = 'HKLM\SOFTWARE\Policies\Microsoft\Windows\Windows Error Reporting'; Name = 'DontShowUI'; Type = 'DWord'; Data = 1 }
        @{ Path = 'HKLM\SOFTWARE\Policies\Microsoft\Windows\Windows Error Reporting'; Name = 'LoggingDisabled'; Type = 'DWord'; Data = 1 }
        # DontSendAdditionalData is only documented as a user policy; the machine-wide WER
        # setting of the same name is undocumented but read by WER - kept as belt and braces.
        @{ Path = 'HKLM\SOFTWARE\Policies\Microsoft\Windows\Windows Error Reporting'; Name = 'DontSendAdditionalData'; Type = 'DWord'; Data = 1 }
        # Undocumented CBS-internal flag; kept, but nothing on MS Learn covers it.
        @{ Path = 'HKLM\Software\Microsoft\Windows\CurrentVersion\Component Based Servicing'; Name = 'DisableWerReporting'; Type = 'DWord'; Data = 1 }
        # Do not send a Windows error report when a generic driver is installed on a device
        @{ Path = 'HKLM\SOFTWARE\Policies\Microsoft\Windows\DeviceInstall\Settings'; Name = 'DisableSendGenericDriverNotFoundToWER'; Type = 'DWord'; Data = 1 }
        # Prevent Windows from sending an error report when a device driver requests additional software during installation
        @{ Path = 'HKLM\SOFTWARE\Policies\Microsoft\Windows\DeviceInstall\Settings'; Name = 'DisableSendRequestAdditionalSoftwareToWER'; Type = 'DWord'; Data = 1 }
    )
}
