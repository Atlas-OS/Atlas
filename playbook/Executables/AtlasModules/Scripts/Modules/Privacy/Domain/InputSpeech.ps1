function Disable-NETCLITelemetry {
    # 'User' scope writes to HKCU and persists across sessions without needing a restart
    [Environment]::SetEnvironmentVariable('DOTNET_CLI_TELEMETRY_OPTOUT', '1', 'User')
}

function Disable-InputTelemetry {
    # Stops Windows from collecting what you type and draw to improve its handwriting/text models
    $path = 'HKCU:\SOFTWARE\Microsoft\InputPersonalization'
    $null = New-Item -Path $path -Force -ErrorAction SilentlyContinue
    Set-ItemProperty -Path $path -Name 'RestrictImplicitInkCollection' -Value 1 -Type DWord -Force
    Set-ItemProperty -Path $path -Name 'RestrictImplicitTextCollection' -Value 1 -Type DWord -Force
}

function Disable-OnlineSpeechRecognition {
    # HasAccepted 0 means the user has not agreed to send voice data to Microsoft servers
    $null = New-Item -Path 'HKCU:\SOFTWARE\Microsoft\Speech_OneCore\Settings\OnlineSpeechPrivacy' -Force -ErrorAction SilentlyContinue
    Set-ItemProperty -Path 'HKCU:\SOFTWARE\Microsoft\Speech_OneCore\Settings\OnlineSpeechPrivacy' -Name 'HasAccepted' -Value 0 -Type DWord -Force
}

function Disable-LanguageListAccess {
    # Browsers can read the Accept-Language header to identify users; this blocks that
    $null = New-Item -Path 'HKCU:\Control Panel\International\User Profile' -Force -ErrorAction SilentlyContinue
    Set-ItemProperty -Path 'HKCU:\Control Panel\International\User Profile' -Name 'HttpAcceptLanguageOptOut' -Value 1 -Type DWord -Force
}
