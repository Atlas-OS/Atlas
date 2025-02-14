function Set-ContentDelivery{
    $key = "HKCU\SOFTWARE\Microsoft\Windows\CurrentVersion\ContentDeliveryManager";
    $data = "0"
    $values = @(
    "ContentDeliveryAllowed",
    "FeatureManagementEnabled",
    "SubscribedContentEnabled",
    "RemediationRequired",
    "OemPreInstalledAppsEnabled",
    "PreInstalledAppsEnabled",
    "PreInstalledAppsEverEnabled",
    "SilentInstalledAppsEnabled",
    "EnableAccountNotifications",
    "SubscribedContent-310093Enabled",
    "SubscribedContent-338393Enabled",
    "SubscribedContent-353694Enabled",
    "SubscribedContent-353696Enabled",
    "SubscribedContent-338388Enabled",
    "SubscribedContent-338387Enabled",
    "SubscribedContent-338389Enabled",
    "SystemPaneSuggestionsEnabled",
    "RotatingLockScreenOverlayEnabled",
    "SoftLandingEnabled"
    )

    foreach ($value in $values){
        reg add $key /v $value /t REG_DWORD /d $data /f > $null
    }
    reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\SystemSettings\AccountNotifications" /t REG_DWORD /v 'EnableAccountNotifications' /d "0" /f > $null
}

function Set-StorageSense{
    $key = "HKCU\SOFTWARE\Microsoft\Windows\CurrentVersion\StorageSense\Parameters\StoragePolicy"
    $values = @(
        "32",
        "02",
        "128",
        "08",
        "256"
    )
    
    foreach ($value in $values){
        reg add $key /t REG_DWORD /v $value /d "0" /f
    }
    reg add $key /t REG_DWORD /v '01' /d "1" /f
    reg add $key /t REG_DWORD /v '1024' /d "1" /f
    reg add $key /t REG_DWORD /v '04' /d "1" /f
    reg add $key /t REG_DWORD /v '2048' /d "30" /f
    Start-ScheduledTask -TaskPath "\Microsoft\Windows\DiskCleanup" -TaskName "SilentCleanup"
}

function Set-DisableStorageSense {
    $arg = "/Online /Set-ReservedStorageState /State:Disabled"
    dism.exe $arg
}

function Set-DisabledScheduledTasks {
    Disable-ScheduledTask -TaskPath "\Microsoft\Windows\Application Experience\" -TaskName "PcaPatchDbTask"
    Disable-ScheduledTask -TaskPath "\Microsoft\Windows\AppxDeploymentClient\" -TaskName "UCPD velocity" -ErrorAction SilentlyContinue
    Disable-ScheduledTask -TaskPath "\Microsoft\Windows\Flighting\FeatureConfig\" -TaskName "UsageDataReporting" -ErrorAction SilentlyContinue
    reg delete "HKLM\System\CurrentControlSet\Control\Ubpm" /v "CriticalMaintenance_UsageDataReporting"
}

function Invoke-AllDebloatOptimizations {
    Set-ContentDelivery
    Set-StorageSense
    Set-DisableStorageSense
    Set-DisabledScheduledTasks
}

Export-ModuleMember -Function Invoke-AllDebloatOptimizations
