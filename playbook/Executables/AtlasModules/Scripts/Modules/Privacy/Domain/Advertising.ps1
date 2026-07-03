function Disable-AdvertisingID {
    # User-side: stops apps from reading the advertising ID
    $null = New-Item -Path 'HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\AdvertisingInfo' -Force -ErrorAction SilentlyContinue
    Set-ItemProperty -Path 'HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\AdvertisingInfo' -Name 'Enabled' -Value 0 -Type DWord -Force
    # Machine-side policy: enforces the setting system-wide regardless of user preference
    $null = New-Item -Path 'HKLM:\Software\Policies\Microsoft\Windows\AdvertisingInfo' -Force -ErrorAction SilentlyContinue
    Set-ItemProperty -Path 'HKLM:\Software\Policies\Microsoft\Windows\AdvertisingInfo' -Name 'DisabledByGroupPolicy' -Value 1 -Type DWord -Force
}

function Disable-SyncProviderNotifications {
    # Stops OneDrive and other sync apps from showing ads inside File Explorer
    Set-ItemProperty -Path 'HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\Advanced' -Name 'ShowSyncProviderNotifications' -Value 0 -Type DWord -Force
}
