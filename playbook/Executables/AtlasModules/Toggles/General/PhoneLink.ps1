function Disable-AtlasPhoneLinkMachine {
    param($Toggle)

    Import-AtlasModule -Name Atlas.Shell
    Set-AtlasSettingsPageVisibility -Operation hide -Page mobile-devices -NoProcessCleanup

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
    Import-AtlasModule -Name Atlas.Appx
    Remove-AtlasPhoneLinkAppx

    if (-not $Toggle.Silent) {
        if (Read-AtlasYesNo -Question 'Also turn off automatic updates for Microsoft Store apps?') {
            Set-AtlasRegistryValue `
                -Path 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\WindowsStore\WindowsUpdate' `
                -Name 'AutoDownload' -Type DWord -Data 2
        }
    }
}

function Enable-AtlasPhoneLinkMachine {
    param($Toggle)

    # These settings affect other products too. Replay must not infer consent to
    # change them from the recorded Phone Link choice.
    if (-not $Toggle.Silent) {
        if (Read-AtlasYesNo -Question 'Allow Microsoft account sign-in on this PC? Phone Link usually needs it.') {
            Remove-AtlasRegistryValue -Path 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System' -Name NoConnectedUser
        }
        if (Read-AtlasYesNo -Question 'Allow Windows consumer features? This can also bring back suggested apps.') {
            Remove-AtlasRegistryValue -Path 'HKLM:\SOFTWARE\Policies\Microsoft\Windows\CloudContent' -Name DisableWindowsConsumerFeatures
        }
        if (Read-AtlasYesNo -Question 'Turn on automatic updates for all Microsoft Store apps?') {
            Set-AtlasRegistryValue -Path 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\WindowsStore\WindowsUpdate' -Name AutoDownload -Type DWord -Data 4
        }
    }
    Import-AtlasModule -Name Atlas.Shell
    Set-AtlasSettingsPageVisibility -Operation unhide -Page mobile-devices -NoProcessCleanup
}

function Enable-AtlasPhoneLinkUser {
    param($Toggle)

    if ($Toggle.Silent) {
        return
    }
    Write-AtlasStep -Text 'Opening Settings > Bluetooth & devices > Mobile devices...'
    Start-Process 'ms-settings:mobile-devices' -ErrorAction Stop
    Write-AtlasNextStep -Text 'Link your phone from the Mobile devices page that just opened.'
}
