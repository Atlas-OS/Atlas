# Optimizes NTFS for performance
function Optimize-NTFS {
    fsutil behavior set disablelastaccess 1
    fsutil behavior set disable8dot3 1
}

# Disables Automatic Folder Discovery to improve File Explorer performance
function Disable-AutoFolderDiscovery {
    & "$windir\AtlasDesktop\4. Interface Tweaks\File Explorer Customization\Automatic Folder Discovery\Disable Automatic Folder Discovery (default).cmd" /justcontext
}

# Disables background apps to reduce resource usage
function Disable-BackgroundApps {
    $key1 = "HKCU\SOFTWARE\Microsoft\Windows\CurrentVersion\BackgroundAccessApplications"
    reg add $key1 /v "GlobalUserDisabled" /t REG_DWORD /d 1 /f

    $key2 = "HKCU\SOFTWARE\Microsoft\Windows\CurrentVersion\Search"
    reg add $key2 /v "BackgroundAppGlobalToggle" /t REG_DWORD /d 0 /f
}

# Disables Xbox Game Bar and related settings
function Disable-GameBar {
    $keys = @(
        "HKCU\System\GameConfigStore",
        "HKCU\SOFTWARE\Microsoft\Windows\CurrentVersion\GameDVR",
        "HKCU\SOFTWARE\Microsoft\GameBar",
        "HKLM\SOFTWARE\Microsoft\WindowsRuntime\ActivatableClassId\Windows.Gaming.GameBar.PresenceServer.Internal.PresenceWriter",
        "HKLM\SOFTWARE\Policies\Microsoft\Windows\GameDVR",
        "HKLM\SOFTWARE\Microsoft\PolicyManager\default\ApplicationManagement\AllowGameDVR"
    )
    
    $values = @(
        @{ Key = $keys[0]; Name = "GameDVR_Enabled"; Data = 0 },
        @{ Key = $keys[1]; Name = "AppCaptureEnabled"; Data = 0 },
        @{ Key = $keys[2]; Name = "GamePanelStartupTipIndex"; Data = 3 },
        @{ Key = $keys[2]; Name = "ShowStartupPanel"; Data = 0 },
        @{ Key = $keys[2]; Name = "UseNexusForGameBarEnabled"; Data = 0 },
        @{ Key = $keys[3]; Name = "ActivationType"; Data = 0 },
        @{ Key = $keys[4]; Name = "AllowGameDVR"; Data = 0 },
        @{ Key = $keys[5]; Name = "value"; Data = 0 }
    )

    foreach ($entry in $values) {
        reg add $entry.Key /v $entry.Name /t REG_DWORD /d $entry.Data /f
    }
}

# Disables Modern Standby's SleepStudy feature
function Disable-SleepStudy {
    Start-Process -FilePath "wevtutil.exe" -ArgumentList 'set-log "Microsoft-Windows-SleepStudy/Diagnostic" /e:false' -NoNewWindow -Wait
    Start-Process -FilePath "wevtutil.exe" -ArgumentList 'set-log "Microsoft-Windows-Kernel-Processor-Power/Diagnostic" /e:false' -NoNewWindow -Wait
    Start-Process -FilePath "wevtutil.exe" -ArgumentList 'set-log "Microsoft-Windows-UserModePowerService/Diagnostic" /e:false' -NoNewWindow -Wait
    schtasks /Change /TN "\Microsoft\Windows\Power Efficiency Diagnostics\AnalyzeSystem" /Disable
}

# Executes all optimizations in sequence
function Invoke-AllPerformanceOptimizations {
    Write-Host "Optimizing NTFS"
    Optimize-NTFS
    Write-Host "disabling auto folder discovery"
    Disable-AutoFolderDiscovery
    Write-Host "disabling background apps"
    Disable-BackgroundApps
    Write-Host "disabling game bar"
    Disable-GameBar
    Write-Host "disabling sleep study"
    Disable-SleepStudy
}

Export-ModuleMember -Function Invoke-AllPerformanceOptimizations