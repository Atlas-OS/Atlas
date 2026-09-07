function Disable-AtlasLocation {
    param($Toggle)

    Import-AtlasModule -Name Atlas.Privacy
    Set-AtlasLocationMachineState -State Disable
}

function Enable-AtlasLocation {
    param($Toggle)

    Import-AtlasModule -Name Atlas.Privacy
    Set-AtlasLocationMachineState -State Enable

    # The "Unlock Find My Device" prompt is interactive-only so silent/upgrade
    # re-apply never hangs; in silent mode Find My Device is preserved.
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
