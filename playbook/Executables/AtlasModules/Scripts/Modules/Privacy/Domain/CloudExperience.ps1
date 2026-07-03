function Disable-DeviceSetupSuggestions {
    # ScoobeSystemSettingEnabled controls the post-OOBE setup suggestions prompt
    $null = New-Item -Path 'HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\UserProfileEngagement' -Force -ErrorAction SilentlyContinue
    Set-ItemProperty -Path 'HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\UserProfileEngagement' -Name 'ScoobeSystemSettingEnabled' -Value 0 -Type DWord -Force
}

function Disable-TailoredExperiences {
    # User setting: stops Windows from using diagnostic data to personalize tips and suggestions
    $null = New-Item -Path 'HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Privacy' -Force -ErrorAction SilentlyContinue
    Set-ItemProperty -Path 'HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Privacy' -Name 'TailoredExperiencesWithDiagnosticDataEnabled' -Value 0 -Type DWord -Force

    # Policy setting: enforces the same restriction via Group Policy so it cannot be toggled back in Settings
    $null = New-Item -Path 'HKCU:\SOFTWARE\Policies\Microsoft\Windows\CloudContent' -Force -ErrorAction SilentlyContinue
    Set-ItemProperty -Path 'HKCU:\SOFTWARE\Policies\Microsoft\Windows\CloudContent' -Name 'DisableTailoredExperiencesWithDiagnosticData' -Value 1 -Type DWord -Force
}

function Disable-UserActivityUpload {
    # Activity Feed tracks what you open and do; these three keys together disable collection and upload
    $path = 'HKLM:\SOFTWARE\Policies\Microsoft\Windows\System'
    $null = New-Item -Path $path -Force -ErrorAction SilentlyContinue
    Set-ItemProperty -Path $path -Name 'EnableActivityFeed'    -Value 0 -Type DWord -Force
    Set-ItemProperty -Path $path -Name 'PublishUserActivities' -Value 0 -Type DWord -Force
    Set-ItemProperty -Path $path -Name 'UploadUserActivities'  -Value 0 -Type DWord -Force
}
