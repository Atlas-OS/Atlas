# Disables Advertising ID for privacy
function Disable-AdvertisingID {
    reg add "HKCU\SOFTWARE\Microsoft\Windows\CurrentVersion\AdvertisingInfo" /v "Enabled" /t REG_DWORD /d 0 /f
    reg add "HKLM\Software\Policies\Microsoft\Windows\AdvertisingInfo" /v "DisabledByGroupPolicy" /t REG_DWORD /d 1 /f
}

# Disables Sync Provider Notifications in File Explorer
function Disable-SyncProviderNotifications {
    reg add "HKCU\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\Advanced" /v "ShowSyncProviderNotifications" /t REG_DWORD /d 0 /f
}

# Disables NVIDIA Control Panel telemetry
function Disable-NvidiaTelemetry {
    reg add "HKCU\Software\NVIDIA Corporation\NVControlPanel2\Client" /v "OptInOrOutPreference" /t REG_DWORD /d 0 /f
}

# Disables Microsoft Office telemetry
function Disable-OfficeTelemetry {
    reg add "HKCU\Software\Policies\Microsoft\office\16.0\common" /v "sendcustomerdata" /t REG_DWORD /d 0 /f
    reg add "HKCU\Software\Policies\Microsoft\office\common\clienttelemetry" /v "sendtelemetry" /t REG_DWORD /d 3 /f
    reg add "HKCU\Software\Policies\Microsoft\office\16.0\common" /v "qmenable" /t REG_DWORD /d 0 /f
}

# Disables Windows Settings Sync
function Disable-SettingsSync {
    $path = "HKLM\SOFTWARE\Policies\Microsoft\Windows\SettingSync"
    reg add $path /v "DisableSettingSync" /t REG_DWORD /d 2 /f
    reg add $path /v "DisableSettingSyncUserOverride" /t REG_DWORD /d 1 /f
    reg add $path /v "DisableSyncOnPaidNetwork" /t REG_DWORD /d 1 /f
    reg add $path /v "DisableWindowsSettingSync" /t REG_DWORD /d 2 /f
}

# Disables Suggested Ways to Finish Setting Up Your Device
function Disable-DeviceSetupSuggestions {
    reg add "HKCU\SOFTWARE\Microsoft\Windows\CurrentVersion\UserProfileEngagement" /v "ScoobeSystemSettingEnabled" /t REG_DWORD /d 0 /f
}

# Disallows Message Service Cloud Sync
function Disable-MessageServiceSync {
    reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows\Messaging" /v "AllowMessageSync" /t REG_DWORD /d 0 /f
}

# Disables Key Management System Telemetry
function Disable-KMSTelemetry {
    reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows NT\CurrentVersion\Software Protection Platform" /v "NoGenTicket" /t REG_DWORD /d 1 /f
}

# Disables Customer Experience Improvement Program
function Disable-CustomerExperienceProgram {
    reg add "HKLM\SOFTWARE\Policies\Microsoft\AppV\CEIP" /v "CEIPEnable" /t REG_DWORD /d 0 /f
    reg add "HKLM\SOFTWARE\Policies\Microsoft\SQMClient\Windows" /v "CEIPEnable" /t REG_DWORD /d 0 /f
}

# Disables Diagnostic Tracing
function Disable-DiagnosticTracing {
    reg add "HKLM\SYSTEM\CurrentControlSet\Control\Diagnostics\Performance" /v "DisableDiagnosticTracing" /t REG_DWORD /d 1 /f
}

# Disables .NET CLI Telemetry
function Disable-NETCLITelemetry {
    setx DOTNET_CLI_TELEMETRY_OPTOUT 1
}

# Disables Input Telemetry (text, handwriting, and ink)
function Disable-InputTelemetry {
    reg add "HKCU\SOFTWARE\Microsoft\InputPersonalization" /v "RestrictImplicitInkCollection" /t REG_DWORD /d 1 /f
    reg add "HKCU\SOFTWARE\Microsoft\InputPersonalization" /v "RestrictImplicitTextCollection" /t REG_DWORD /d 1 /f
}

# Disables Windows Telemetry & Data Collection
function Disable-Telemetry {
    reg add "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\DataCollection" /v "AllowTelemetry" /t REG_DWORD /d 0 /f
}

# Configures App Permissions for privacy
function Set-AppPermissions {
    reg add "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\CapabilityAccessManager\ConsentStore\location" /v "Value" /t REG_SZ /d "Deny" /f
}

# Configures Windows Media Player for privacy
function Set-WindowsMediaPlayer {
    reg add "HKCU\SOFTWARE\Microsoft\MediaPlayer\Preferences" /v "AcceptedPrivacyStatement" /t REG_DWORD /d 1 /f
}

# Disables Activity Feed in Task View
function Disable-ActivityFeed {
    reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows\System" /v "EnableActivityFeed" /t REG_DWORD /d 0 /f
}

# Disables App Launch Tracking
function Disable-AppLaunchTracking {
    reg add "HKCU\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\Advanced" /v "Start_TrackProgs" /t REG_DWORD /d 0 /f
}

# Disables Experimentation
function Disable-Experimentation {
    reg add "HKLM\SOFTWARE\Microsoft\PolicyManager\default\System\AllowExperimentation" /v "Value" /t REG_DWORD /d 0 /f
}

# Disables Windows Lockscreen Camera
function Disable-LockscreenCamera {
    reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows\Personalization" /v "NoLockScreenCamera" /t REG_DWORD /d 1 /f
}

# Disables Online Speech Recognition
function Disable-OnlineSpeechRecognition {
    reg add "HKCU\SOFTWARE\Microsoft\Speech_OneCore\Settings\OnlineSpeechPrivacy" /v "HasAccepted" /t REG_DWORD /d 0 /f
}

# Disables Windows Error Reporting
function Disable-ErrorReporting {
    reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows\Windows Error Reporting" /v "Disabled" /t REG_DWORD /d 1 /f
}

# Disables Device Health Attestation Monitoring and Reporting
function Disable-DeviceHealthAttestation {
    reg add "HKLM\SOFTWARE\Policies\Microsoft\DeviceHealthAttestationService" /v "EnableDeviceHealthAttestationService" /t REG_DWORD /d 0 /f
}

# Disables Performance Tracking (responsiveness events)
function Disable-PerformanceTrack {
    reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows\WDI\{9c5a40da-b965-4fc3-8781-88dd50a6299d}" /v "ScenarioExecutionEnabled" /t REG_DWORD /d 0 /f
}

# Disables the OOBE Privacy Experience
function Disable-OOBEPrivacyExperience {
    reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows\OOBE" /v "DisablePrivacyExperience" /t REG_DWORD /d 1 /f
}

# Disables Recall Snapshots (24H2+)
function Disable-RecallSnapshots {
    Start-Process -FilePath "reg" -ArgumentList "import `"AtlasDesktop\3. General Configuration\AI Features\Recall\Disable Recall Support (default).reg`"" -NoNewWindow -Wait
}

# Disables Resultant Set of Policy (RSoP) Logging
function Disable-RSoPLogging {
    reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows\System" /v "RSoPLogging" /t REG_DWORD /d 0 /f
}

# Disables Automatic Updates of Speech Data
function Disable-SpeechDataUpdates {
    reg add "HKLM\SOFTWARE\Policies\Microsoft\Speech" /v "AllowSpeechModelUpdate" /t REG_DWORD /d 0 /f
}

# Prevents using Diagnostic Data for Tailored Experiences
function Disable-TailoredExperiences {
    reg add "HKCU\SOFTWARE\Microsoft\Windows\CurrentVersion\Privacy" /v "TailoredExperiencesWithDiagnosticDataEnabled" /t REG_DWORD /d 0 /f
    reg add "HKCU\SOFTWARE\Policies\Microsoft\Windows\CloudContent" /v "DisableTailoredExperiencesWithDiagnosticData" /t REG_DWORD /d 1 /f
}

# Disables Most Frequently Used Applications in Start Menu
function Disable-FrequentApps {
    reg add "HKCU\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\Explorer" /v "NoInstrumentation" /t REG_DWORD /d 1 /f
}

# Disables Website Access to Language List (prevents fingerprinting)
function Disable-LanguageListAccess {
    reg add "HKCU\Control Panel\International\User Profile" /v "HttpAcceptLanguageOptOut" /t REG_DWORD /d 1 /f
}

# Disables Windows Error Reporting
function Disable-ErrorReporting {
    $keys = @(
        "HKCU\SOFTWARE\Policies\Microsoft\Windows\Windows Error Reporting",
        "HKLM\SOFTWARE\Policies\Microsoft\PCHealth\ErrorReporting",
        "HKLM\SOFTWARE\Policies\Microsoft\Windows\Windows Error Reporting",
        "HKLM\SOFTWARE\Policies\Microsoft\Windows\DeviceInstall\Settings",
        "HKLM\Software\Microsoft\Windows\CurrentVersion\Component Based Servicing"
    )

    $values = @(
        @{ Key = $keys[0]; Name = "Disabled"; Data = 1 },
        @{ Key = $keys[1]; Name = "DoReport"; Data = 0 },
        @{ Key = $keys[2]; Name = "Disabled"; Data = 1 },
        @{ Key = $keys[2]; Name = "DontShowUI"; Data = 1 },
        @{ Key = $keys[2]; Name = "LoggingDisabled"; Data = 1 },
        @{ Key = $keys[2]; Name = "DontSendAdditionalData"; Data = 1 },
        @{ Key = $keys[3]; Name = "DisableSendGenericDriverNotFoundToWER"; Data = 1 },
        @{ Key = $keys[3]; Name = "DisableSendRequestAdditionalSoftwareToWER"; Data = 1 },
        @{ Key = $keys[4]; Name = "DisableWerReporting"; Data = 1 }
    )

    foreach ($entry in $values) {
        reg add $entry.Key /v $entry.Name /t REG_DWORD /d $entry.Data /f
    }
}

# Prevents Non-Local User Accounts
function Disable-NonLocalAccounts {
    reg add "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System" /v "NoConnectedUser" /t REG_DWORD /d 1 /f
}

# Disables User Activity Upload
function Disable-UserActivityUpload {
    reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows\System" /v "UploadUserActivities" /t REG_DWORD /d 0 /f
}

# Configures Search Privacy
function Set-SearchPrivacy {
    reg add "HKCU\SOFTWARE\Microsoft\Windows\CurrentVersion\Search" /v "BingSearchEnabled" /t REG_DWORD /d 0 /f
}

# Executes all privacy-related optimizations
function Invoke-AllPrivacyOptimizations {
    Disable-AdvertisingID
    Disable-SyncProviderNotifications
    Disable-NvidiaTelemetry
    Disable-OfficeTelemetry
    Disable-SettingsSync
    Disable-DeviceSetupSuggestions
    Disable-MessageServiceSync
    Disable-KMSTelemetry
    Disable-CustomerExperienceProgram
    Disable-DiagnosticTracing
    Disable-NETCLITelemetry
    Disable-InputTelemetry
    Disable-Telemetry
    Set-AppPermissions
    Set-WindowsMediaPlayer
    Disable-ActivityFeed
    Disable-AppLaunchTracking
    Disable-Experimentation
    Disable-LockscreenCamera
    Disable-OnlineSpeechRecognition
    Disable-NonLocalAccounts
    Disable-UserActivityUpload
    Set-SearchPrivacy
    Disable-DeviceHealthAttestation
    Disable-PerformanceTrack
    Disable-OOBEPrivacyExperience
    Disable-RecallSnapshots
    Disable-RSoPLogging
    Disable-SpeechDataUpdates
    Disable-TailoredExperiences
    Disable-FrequentApps
    Disable-LanguageListAccess
    Disable-ErrorReporting
}

Export-ModuleMember -Function Invoke-AllPrivacyOptimizations