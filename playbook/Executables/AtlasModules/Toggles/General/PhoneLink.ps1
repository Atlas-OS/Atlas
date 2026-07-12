# Toggle: Mobile Devices / Phone Link (CDPSvc, cross-device resume, YourPhone appx).
# The settings page is opened only for an interactive enable.
$machineAction = {
    param($Toggle)

    $registryModule = Join-Path $Toggle.ScriptsPath `
        'Modules\Atlas.Registry\Atlas.Registry.psd1'
    Import-Module -Name $registryModule -Force -ErrorAction Stop

    $settingsPages = Join-Path $Toggle.ScriptsPath `
        'Internal\Set-SettingsPageVisibility.ps1'
    $setServiceStartup = Join-Path $Toggle.ScriptsPath `
        'Internal\Set-ServiceStartup.ps1'

    if ($Toggle.State -ceq 'Enable') {
        Remove-AtlasRegistryValue `
            -Path 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System' `
            -Name 'NoConnectedUser'
        Remove-AtlasRegistryValue `
            -Path 'HKLM:\SOFTWARE\Policies\Microsoft\Windows\CloudContent' `
            -Name 'DisableWindowsConsumerFeatures'

        & $setServiceStartup -Name 'CDPSvc' -Start 3
        Set-AtlasRegistryValue `
            -Path 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\WindowsStore\WindowsUpdate' `
            -Name 'AutoDownload' -Type DWord -Data 4
        & $settingsPages unhide mobile-devices -Silent:$Toggle.Silent -NoProcessCleanup
        return
    }

    Import-Module -Name (Join-Path $Toggle.ScriptsPath `
            'Modules\Atlas.Appx\Atlas.Appx.psd1') -Force -ErrorAction Stop
    Import-Module -Name (Join-Path $Toggle.ScriptsPath `
            'Modules\Atlas.TasksProcs\Atlas.TasksProcs.psd1') -Force -ErrorAction Stop

    Set-AtlasRegistryValue `
        -Path 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System' `
        -Name 'NoConnectedUser' -Type DWord -Data 1
    & $settingsPages hide mobile-devices -Silent:$Toggle.Silent -NoProcessCleanup
    & $setServiceStartup -Name 'CDPSvc' -Start 4 -AllowMissing

    # Limit cleanup to the initiating Windows session; another signed-in user's
    # RuntimeBroker or Phone Link process must remain untouched.
    $sessionId = [Diagnostics.Process]::GetCurrentProcess().SessionId
    if ($sessionId -gt 0) {
        Stop-AtlasProcess `
            -Name @('RuntimeBroker', 'PhoneExperienceHost') `
            -SessionId $sessionId `
            -StopOnError `
            -WaitTimeoutMilliseconds 10000
    }
    Remove-AtlasPhoneLinkAppx

    if (-not $Toggle.Silent) {
        $autoDownload = if ((Read-Host 'Would you like to disable Store auto-updates? [Y/N]') `
            -match '^(y|yes)$') { 2 } else { 4 }
        Set-AtlasRegistryValue `
            -Path 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\WindowsStore\WindowsUpdate' `
            -Name 'AutoDownload' -Type DWord -Data $autoDownload
    }
}

$userAction = {
    param($Toggle)

    Import-Module -Name (Join-Path $Toggle.ScriptsPath `
            'Modules\Atlas.Registry\Atlas.Registry.psd1') -Force -ErrorAction Stop

    $enable = $Toggle.State -ceq 'Enable'
    $resumeAllowed = if ($enable) { 1 } else { 0 }
    $disableResume = if ($enable) { 0 } else { 1 }
    Set-AtlasRegistryValue `
        -Path 'HKCU:\Software\Microsoft\Windows\CurrentVersion\CrossDeviceResume\Configuration' `
        -Name 'IsResumeAllowed' -Type DWord -Data $resumeAllowed
    Set-AtlasRegistryValue `
        -Path 'HKCU:\SOFTWARE\Microsoft\PolicyManager\default\Connectivity\DisableCrossDeviceResume' `
        -Name 'Value' -Type DWord -Data $disableResume

    if (-not $enable) {
        $cdp = 'HKCU:\Software\Microsoft\Windows\CurrentVersion\CDP'
        Set-AtlasRegistryValue -Path $cdp -Name 'NearShareChannelUserAuthzPolicy' `
            -Type DWord -Data 0
        Set-AtlasRegistryValue -Path $cdp -Name 'CdpSessionUserAuthzPolicy' `
            -Type DWord -Data 1
        Set-AtlasRegistryValue -Path "$cdp\SettingsPage" `
            -Name 'BluetoothLastDisabledNearShare' -Type DWord -Data 0
    }

    if ($Toggle.Silent) {
        return
    }
    if ($enable) {
        Start-Process 'ms-settings:mobile-devices' -ErrorAction Stop
        Write-Host "`nPhone Link has been enabled. You can now sync your phone."
    }
    else {
        Write-Host "`nPhone Link has been disabled."
    }
}

@{
    Name      = 'PhoneLink'
    Elevation = 'Admin'
    States    = [ordered]@{
        Disable = @{
            StateValue       = 0
            Launcher         = '3. General Configuration\Mobile Devices (Phone Link)\Disable Mobile Device Settings (default).cmd'
            Reboot           = 'None'
            StateRecordScope = 'Machine'
            MachineAction    = $machineAction
            UserAction       = $userAction
        }
        Enable  = @{
            StateValue       = 1
            Launcher         = '3. General Configuration\Mobile Devices (Phone Link)\Enable Mobile Device Settings.cmd'
            Reboot           = 'None'
            StateRecordScope = 'Machine'
            MachineAction    = $machineAction
            UserAction       = $userAction
        }
    }
}
