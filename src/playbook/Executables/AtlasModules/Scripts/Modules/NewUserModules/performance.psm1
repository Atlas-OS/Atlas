# Disables paging settings for improved performanc
function Disable-PagingSettings {
    $key = "HKLM\SYSTEM\CurrentControlSet\Control\Session Manager\Memory Management"
    reg add $key /v "DisablePagingExecutive" /t REG_DWORD /d 1 /f
    reg add $key /v "DisablePageCombining" /t REG_DWORD /d 1 /f
}

# Disables Service Host splitting (except Xbox services) to reduce RAM usage
function Disable-ServiceHostSplitting {
    Get-ChildItem 'HKLM:\SYSTEM\CurrentControlSet\Services' |
        Where-Object { $_.Name -notmatch 'Xbl|Xbox' } |
        ForEach-Object {
            if ($null -ne (Get-ItemProperty -Path "Registry::$_" -ErrorAction SilentlyContinue).Start) {
                Set-ItemProperty -Path "Registry::$_" -Name 'SvcHostSplitDisable' -Type DWORD -Value 1 -Force -ErrorAction SilentlyContinue
            }
        }
}

# Optimizes NTFS for performance
function Optimize-NTFS {
    fsutil behavior set disablelastaccess 1
    fsutil behavior set disable8dot3 1
}

# Prioritizes foreground applications for process scheduling
function Optimize-ForegroundApps {
    $key = "HKLM\SYSTEM\CurrentControlSet\Control\PriorityControl"
    reg add $key /v "Win32PrioritySeparation" /t REG_DWORD /d 38 /f
}

# Sets Automatic Maintenance settings
function Set-AutomaticMaintenance {
    $key = "HKLM\SOFTWARE\Policies\Microsoft\Windows\Task Scheduler\Maintenance"
    reg add $key /v "WakeUp" /t REG_DWORD /d 0 /f
}

# Sets Multimedia Class Scheduler Service for performance
function Set-MMCSS {
    $key = "HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Multimedia\SystemProfile"
    reg add $key /v "SystemResponsiveness" /t REG_DWORD /d 10 /f
}

# Disables Automatic Folder Discovery to improve File Explorer performance
function Disable-AutoFolderDiscovery {
    Start-Process -FilePath "reg" -ArgumentList "import `"AtlasDesktop\4. Interface Tweaks\File Explorer Customization\Automatic Folder Discovery\Disable Automatic Folder Discovery (default).reg`"" -NoNewWindow -Wait
}

# Disables background apps to reduce resource usage
function Disable-BackgroundApps {
    $key1 = "HKCU\SOFTWARE\Microsoft\Windows\CurrentVersion\BackgroundAccessApplications"
    reg add $key1 /v "GlobalUserDisabled" /t REG_DWORD /d 1 /f

    $key2 = "HKCU\SOFTWARE\Microsoft\Windows\CurrentVersion\Search"
    reg add $key2 /v "BackgroundAppGlobalToggle" /t REG_DWORD /d 0 /f
}

# Disables Fault Tolerant Heap (FTH) to avoid performance penalties
function Disable-FTH {
    if ($env:PROCESSOR_ARCHITECTURE -eq "ARM64") {
        Remove-Item -Path "$env:windir\AtlasDesktop\7. Security\Mitigations\Fault Tolerant Heap" -Recurse -Force -ErrorAction SilentlyContinue
    } elseif ($env:PROCESSOR_ARCHITECTURE -eq "AMD64") {
        Start-Process -FilePath "rundll32.exe" -ArgumentList "fthsvc.dll,FthSysprepSpecialize" -NoNewWindow -Wait
        reg add "HKLM\SOFTWARE\Microsoft\FTH" /v "Enabled" /t REG_DWORD /d 0 /f
    }
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

# Respects power modes for Windows Search indexing to prevent battery drain
function Set-SearchIndexingPowerMode {
    $key = "HKLM\Software\Microsoft\Windows Search\Gather\Windows\SystemIndex"
    reg add $key /v "RespectPowerModes" /t REG_DWORD /d 1 /f
}

# Executes all optimizations in sequence
function Invoke-AllPerformanceOptimizations {
    Disable-PagingSettings
    Disable-ServiceHostSplitting
    Optimize-NTFS
    Optimize-ForegroundApps
    Set-AutomaticMaintenance
    Set-MMCSS
    Disable-AutoFolderDiscovery
    Disable-BackgroundApps
    Disable-FTH
    Disable-GameBar
    Disable-SleepStudy
    Set-SearchIndexingPowerMode
}

Export-ModuleMember -Function Invoke-AllPerformanceOptimizations