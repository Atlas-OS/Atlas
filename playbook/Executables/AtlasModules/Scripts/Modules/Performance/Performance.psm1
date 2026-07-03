# Optimizes NTFS for performance
function Optimize-NTFS {
    # Stop tracking last-access timestamps on files; reduces unnecessary disk writes
    fsutil behavior set disablelastaccess 1
    # Disable 8.3 short filename generation; speeds up directory operations on large folders
    fsutil behavior set disable8dot3 1
}

# Disables Automatic Folder Discovery to improve File Explorer performance
function Disable-AutoFolderDiscovery {
    & "$windir\AtlasDesktop\4. Interface Tweaks\File Explorer Customization\Automatic Folder Discovery\Disable Automatic Folder Discovery (default).cmd" /justcontext
}

# Disables background apps to reduce resource usage
function Disable-BackgroundApps {
    # Prevents all UWP apps from running in the background globally for this user
    $key1 = 'HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\BackgroundAccessApplications'
    $null = New-Item -Path $key1 -Force -ErrorAction SilentlyContinue
    Set-ItemProperty -Path $key1 -Name 'GlobalUserDisabled' -Value 1 -Type DWord -Force

    # Stops the Windows Search indexer from running background tasks
    $key2 = 'HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Search'
    $null = New-Item -Path $key2 -Force -ErrorAction SilentlyContinue
    Set-ItemProperty -Path $key2 -Name 'BackgroundAppGlobalToggle' -Value 0 -Type DWord -Force
}

# Disables Xbox Game Bar and related settings
function Disable-GameBar {
    # New-Item -Force is required before Set-ItemProperty; it silently succeeds if the key already exists
    $entries = @(
        @{ Path = 'HKCU:\System\GameConfigStore'; Name = 'GameDVR_Enabled'; Value = 0 },
        @{ Path = 'HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\GameDVR'; Name = 'AppCaptureEnabled'; Value = 0 },
        @{ Path = 'HKCU:\SOFTWARE\Microsoft\GameBar'; Name = 'GamePanelStartupTipIndex'; Value = 3 },
        @{ Path = 'HKCU:\SOFTWARE\Microsoft\GameBar'; Name = 'ShowStartupPanel'; Value = 0 },
        @{ Path = 'HKCU:\SOFTWARE\Microsoft\GameBar'; Name = 'UseNexusForGameBarEnabled'; Value = 0 },
        @{ Path = 'HKLM:\SOFTWARE\Microsoft\WindowsRuntime\ActivatableClassId\Windows.Gaming.GameBar.PresenceServer.Internal.PresenceWriter'; Name = 'ActivationType'; Value = 0 },
        @{ Path = 'HKLM:\SOFTWARE\Policies\Microsoft\Windows\GameDVR'; Name = 'AllowGameDVR'; Value = 0 },
        @{ Path = 'HKLM:\SOFTWARE\Microsoft\PolicyManager\default\ApplicationManagement\AllowGameDVR'; Name = 'value'; Value = 0 }
    )

    foreach ($entry in $entries) {
        $null = New-Item -Path $entry.Path -Force -ErrorAction SilentlyContinue
        Set-ItemProperty -Path $entry.Path -Name $entry.Name -Value $entry.Value -Type DWord -Force
    }
}

# Disables Modern Standby's SleepStudy feature
function Disable-SleepStudy {
    # wevtutil must be called via Start-Process because it does not have a PowerShell equivalent
    # These three event logs are used by SleepStudy to track power activity; disabling them stops the logging
    Start-Process -FilePath 'wevtutil.exe' -ArgumentList 'set-log "Microsoft-Windows-SleepStudy/Diagnostic" /e:false' -NoNewWindow -Wait
    Start-Process -FilePath 'wevtutil.exe' -ArgumentList 'set-log "Microsoft-Windows-Kernel-Processor-Power/Diagnostic" /e:false' -NoNewWindow -Wait
    Start-Process -FilePath 'wevtutil.exe' -ArgumentList 'set-log "Microsoft-Windows-UserModePowerService/Diagnostic" /e:false' -NoNewWindow -Wait
    # AnalyzeSystem runs on every boot to generate power reports; not useful on a tuned system
    Disable-ScheduledTask -TaskPath '\Microsoft\Windows\Power Efficiency Diagnostics\' -TaskName 'AnalyzeSystem' -ErrorAction SilentlyContinue
}

Export-ModuleMember -Function @()
