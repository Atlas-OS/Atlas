function Disable-NvidiaTelemetry {
    # OptInOrOutPreference 0 means opted out of NVIDIA telemetry collection
    $null = New-Item -Path 'HKCU:\Software\NVIDIA Corporation\NVControlPanel2\Client' -Force -ErrorAction SilentlyContinue
    Set-ItemProperty -Path 'HKCU:\Software\NVIDIA Corporation\NVControlPanel2\Client' -Name 'OptInOrOutPreference' -Value 0 -Type DWord -Force
}

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

function Set-WindowsMediaPlayer {
    # AcceptedPrivacyStatement 1 suppresses the privacy prompt on first launch without sending data
    $null = New-Item -Path 'HKCU:\SOFTWARE\Microsoft\MediaPlayer\Preferences' -Force -ErrorAction SilentlyContinue
    Set-ItemProperty -Path 'HKCU:\SOFTWARE\Microsoft\MediaPlayer\Preferences' -Name 'AcceptedPrivacyStatement' -Value 1 -Type DWord -Force
}

function Disable-AppLaunchTracking {
    # Windows normally tracks which apps you open to sort the Start Menu; this disables that
    Set-ItemProperty -Path 'HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\Advanced' -Name 'Start_TrackProgs' -Value 0 -Type DWord -Force
}

function Disable-FrequentApps {
    # NoInstrumentation stops Windows from tracking which apps are opened most often
    $null = New-Item -Path 'HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\Explorer' -Force -ErrorAction SilentlyContinue
    Set-ItemProperty -Path 'HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\Explorer' -Name 'NoInstrumentation' -Value 1 -Type DWord -Force
}
