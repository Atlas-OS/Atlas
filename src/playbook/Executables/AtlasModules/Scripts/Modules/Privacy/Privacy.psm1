# Disables Advertising ID for privacy
function Disable-AdvertisingID {
    # User-side: stops apps from reading the advertising ID
    $null = New-Item -Path 'HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\AdvertisingInfo' -Force -ErrorAction SilentlyContinue
    Set-ItemProperty -Path 'HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\AdvertisingInfo' -Name 'Enabled' -Value 0 -Type DWord -Force
    # Machine-side policy: enforces the setting system-wide regardless of user preference
    $null = New-Item -Path 'HKLM:\Software\Policies\Microsoft\Windows\AdvertisingInfo' -Force -ErrorAction SilentlyContinue
    Set-ItemProperty -Path 'HKLM:\Software\Policies\Microsoft\Windows\AdvertisingInfo' -Name 'DisabledByGroupPolicy' -Value 1 -Type DWord -Force
}

# Disables Sync Provider Notifications in File Explorer
function Disable-SyncProviderNotifications {
    # Stops OneDrive and other sync apps from showing ads inside File Explorer
    Set-ItemProperty -Path 'HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\Advanced' -Name 'ShowSyncProviderNotifications' -Value 0 -Type DWord -Force
}

# Disables NVIDIA Control Panel telemetry
function Disable-NvidiaTelemetry {
    # OptInOrOutPreference 0 means opted out of NVIDIA telemetry collection
    $null = New-Item -Path 'HKCU:\Software\NVIDIA Corporation\NVControlPanel2\Client' -Force -ErrorAction SilentlyContinue
    Set-ItemProperty -Path 'HKCU:\Software\NVIDIA Corporation\NVControlPanel2\Client' -Name 'OptInOrOutPreference' -Value 0 -Type DWord -Force
}

# Disables Microsoft Office telemetry
function Disable-OfficeTelemetry {
    $path1 = 'HKCU:\Software\Policies\Microsoft\office\16.0\common'
    $null = New-Item -Path $path1 -Force -ErrorAction SilentlyContinue
    # sendcustomerdata 0 stops Office from sending usage data; qmenable 0 disables Quality Metrics reporting
    Set-ItemProperty -Path $path1 -Name 'sendcustomerdata' -Value 0 -Type DWord -Force
    Set-ItemProperty -Path $path1 -Name 'qmenable' -Value 0 -Type DWord -Force

    $path2 = 'HKCU:\Software\Policies\Microsoft\office\common\clienttelemetry'
    $null = New-Item -Path $path2 -Force -ErrorAction SilentlyContinue
    # sendtelemetry 3 means disabled; this is an Office-specific enum value, not a simple boolean
    Set-ItemProperty -Path $path2 -Name 'sendtelemetry' -Value 3 -Type DWord -Force
}

# Disables Suggested Ways to Finish Setting Up Your Device
function Disable-DeviceSetupSuggestions {
    # ScoobeSystemSettingEnabled controls the post-OOBE setup suggestions prompt
    $null = New-Item -Path 'HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\UserProfileEngagement' -Force -ErrorAction SilentlyContinue
    Set-ItemProperty -Path 'HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\UserProfileEngagement' -Name 'ScoobeSystemSettingEnabled' -Value 0 -Type DWord -Force
}

# Disables .NET CLI Telemetry
function Disable-NETCLITelemetry {
    # 'User' scope writes to HKCU and persists across sessions without needing a restart
    [Environment]::SetEnvironmentVariable('DOTNET_CLI_TELEMETRY_OPTOUT', '1', 'User')
}

# Disables Input Telemetry (text, handwriting, and ink)
function Disable-InputTelemetry {
    # Stops Windows from collecting what you type and draw to improve its handwriting/text models
    $path = 'HKCU:\SOFTWARE\Microsoft\InputPersonalization'
    $null = New-Item -Path $path -Force -ErrorAction SilentlyContinue
    Set-ItemProperty -Path $path -Name 'RestrictImplicitInkCollection' -Value 1 -Type DWord -Force
    Set-ItemProperty -Path $path -Name 'RestrictImplicitTextCollection' -Value 1 -Type DWord -Force
}

# Configures Windows Media Player for privacy
function Set-WindowsMediaPlayer {
    # AcceptedPrivacyStatement 1 suppresses the privacy prompt on first launch without sending data
    $null = New-Item -Path 'HKCU:\SOFTWARE\Microsoft\MediaPlayer\Preferences' -Force -ErrorAction SilentlyContinue
    Set-ItemProperty -Path 'HKCU:\SOFTWARE\Microsoft\MediaPlayer\Preferences' -Name 'AcceptedPrivacyStatement' -Value 1 -Type DWord -Force
}

# Disables App Launch Tracking
function Disable-AppLaunchTracking {
    # Windows normally tracks which apps you open to sort the Start Menu; this disables that
    Set-ItemProperty -Path 'HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\Advanced' -Name 'Start_TrackProgs' -Value 0 -Type DWord -Force
}

# Disables Online Speech Recognition
function Disable-OnlineSpeechRecognition {
    # HasAccepted 0 means the user has not agreed to send voice data to Microsoft servers
    $null = New-Item -Path 'HKCU:\SOFTWARE\Microsoft\Speech_OneCore\Settings\OnlineSpeechPrivacy' -Force -ErrorAction SilentlyContinue
    Set-ItemProperty -Path 'HKCU:\SOFTWARE\Microsoft\Speech_OneCore\Settings\OnlineSpeechPrivacy' -Name 'HasAccepted' -Value 0 -Type DWord -Force
}

# Disables Recall Snapshots (24H2+)
function Disable-RecallSnapshots {
    # reg.exe import is the only reliable way to apply a .reg file from PowerShell
    & reg.exe import "AtlasDesktop\3. General Configuration\AI Features\Recall\Disable Recall Support (default).reg"
}

# Prevents using Diagnostic Data for Tailored Experiences
function Disable-TailoredExperiences {
    # User setting: stops Windows from using diagnostic data to personalize tips and suggestions
    $null = New-Item -Path 'HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Privacy' -Force -ErrorAction SilentlyContinue
    Set-ItemProperty -Path 'HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Privacy' -Name 'TailoredExperiencesWithDiagnosticDataEnabled' -Value 0 -Type DWord -Force

    # Policy setting: enforces the same restriction via Group Policy so it cannot be toggled back in Settings
    $null = New-Item -Path 'HKCU:\SOFTWARE\Policies\Microsoft\Windows\CloudContent' -Force -ErrorAction SilentlyContinue
    Set-ItemProperty -Path 'HKCU:\SOFTWARE\Policies\Microsoft\Windows\CloudContent' -Name 'DisableTailoredExperiencesWithDiagnosticData' -Value 1 -Type DWord -Force
}

# Disables Most Frequently Used Applications in Start Menu
function Disable-FrequentApps {
    # NoInstrumentation stops Windows from tracking which apps are opened most often
    $null = New-Item -Path 'HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\Explorer' -Force -ErrorAction SilentlyContinue
    Set-ItemProperty -Path 'HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\Explorer' -Name 'NoInstrumentation' -Value 1 -Type DWord -Force
}

# Disables Website Access to Language List (prevents fingerprinting)
function Disable-LanguageListAccess {
    # Browsers can read the Accept-Language header to identify users; this blocks that
    $null = New-Item -Path 'HKCU:\Control Panel\International\User Profile' -Force -ErrorAction SilentlyContinue
    Set-ItemProperty -Path 'HKCU:\Control Panel\International\User Profile' -Name 'HttpAcceptLanguageOptOut' -Value 1 -Type DWord -Force
}

# Disables Windows Error Reporting
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

# Configures Search Privacy
function Set-SearchPrivacy {
    # Stops the Start Menu search bar from sending queries to Bing
    Set-ItemProperty -Path 'HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Search' -Name 'BingSearchEnabled' -Value 0 -Type DWord -Force
}

function Disable-UserActivityUpload {
    # Activity Feed tracks what you open and do; these three keys together disable collection and upload
    $path = 'HKLM:\SOFTWARE\Policies\Microsoft\Windows\System'
    $null = New-Item -Path $path -Force -ErrorAction SilentlyContinue
    Set-ItemProperty -Path $path -Name 'EnableActivityFeed'    -Value 0 -Type DWord -Force
    Set-ItemProperty -Path $path -Name 'PublishUserActivities' -Value 0 -Type DWord -Force
    Set-ItemProperty -Path $path -Name 'UploadUserActivities'  -Value 0 -Type DWord -Force
}

Export-ModuleMember -Function @()
