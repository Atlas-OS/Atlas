# Companion for the Location toggle: turns location services and Find My Device on or off.
# Disable-AtlasLocation and Enable-AtlasLocation run as Administrator when you run a launcher,
# when the install applies the toggle and when an update replays the recorded state.
# Show-AtlasLocationSettings runs in your own unelevated process after Enable, and is replayed
# for each new account at first sign-in.

function Disable-AtlasLocation {
    param($Toggle)

    Import-AtlasModule -Name Atlas.Privacy
    Set-AtlasLocationMachineState -State Disable
}

function Enable-AtlasLocation {
    param($Toggle)

    Import-AtlasModule -Name Atlas.Privacy
    Set-AtlasLocationMachineState -State Enable

    # The Find My Device question is asked only in interactive runs, so a silent run or
    # update replay never waits for an answer; silent runs leave Find My Device as it is.
    if (-not $Toggle.Silent) {
        Import-AtlasModule -Name Atlas.Shell
        $findMyDevice = 'HKLM:\SOFTWARE\Policies\Microsoft\FindMyDevice'
        if (Read-AtlasYesNo -Question 'Also allow Find My Device, which lets your Microsoft account locate this PC?') {
            foreach ($name in @('AllowFindMyDevice', 'LocationSyncEnabled')) {
                Remove-AtlasRegistryValue -Path $findMyDevice -Name $name
            }
            Set-AtlasSettingsPageVisibility -Operation unhide -Page findmydevice
        }
    }
}

function Show-AtlasLocationSettings {
    param($Toggle)
    if (-not $Toggle.Silent) {
        Write-AtlasStep -Text 'Opening Settings > Privacy & security > Location...'
        Start-Process 'ms-settings:privacy-location' -ErrorAction Stop
        Write-AtlasManualStep -Text 'In Settings, turn on Location services, then choose which apps may use your location.'
    }
}
