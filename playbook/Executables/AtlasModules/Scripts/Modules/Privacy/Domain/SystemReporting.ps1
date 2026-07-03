function Disable-RecallSnapshots {
    # reg.exe import is the only reliable way to apply a .reg file from PowerShell
    & reg.exe import "AtlasDesktop\3. General Configuration\AI Features\Recall\Disable Recall Support (default).reg"
}

function Disable-ErrorReporting {
    # Covers both user and machine policy keys to fully suppress crash reporting and error UI
    $entries = @(
        @{ Path = 'HKCU:\SOFTWARE\Policies\Microsoft\Windows\Windows Error Reporting'; Name = 'Disabled'; Value = 1 },
        @{ Path = 'HKLM:\SOFTWARE\Policies\Microsoft\PCHealth\ErrorReporting'; Name = 'DoReport'; Value = 0 },
        @{ Path = 'HKLM:\SOFTWARE\Policies\Microsoft\Windows\Windows Error Reporting'; Name = 'Disabled'; Value = 1 },
        @{ Path = 'HKLM:\SOFTWARE\Policies\Microsoft\Windows\Windows Error Reporting'; Name = 'DontShowUI'; Value = 1 },
        @{ Path = 'HKLM:\SOFTWARE\Policies\Microsoft\Windows\Windows Error Reporting'; Name = 'LoggingDisabled'; Value = 1 },
        @{ Path = 'HKLM:\SOFTWARE\Policies\Microsoft\Windows\Windows Error Reporting'; Name = 'DontSendAdditionalData'; Value = 1 },
        @{ Path = 'HKLM:\SOFTWARE\Policies\Microsoft\Windows\DeviceInstall\Settings'; Name = 'DisableSendGenericDriverNotFoundToWER'; Value = 1 },
        @{ Path = 'HKLM:\SOFTWARE\Policies\Microsoft\Windows\DeviceInstall\Settings'; Name = 'DisableSendRequestAdditionalSoftwareToWER'; Value = 1 },
        @{ Path = 'HKLM:\Software\Microsoft\Windows\CurrentVersion\Component Based Servicing'; Name = 'DisableWerReporting'; Value = 1 }
    )

    foreach ($entry in $entries) {
        $null = New-Item -Path $entry.Path -Force -ErrorAction SilentlyContinue
        Set-ItemProperty -Path $entry.Path -Name $entry.Name -Value $entry.Value -Type DWord -Force
    }
}

function Set-SearchPrivacy {
    # Stops the Start Menu search bar from sending queries to Bing
    Set-ItemProperty -Path 'HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Search' -Name 'BingSearchEnabled' -Value 0 -Type DWord -Force
}
