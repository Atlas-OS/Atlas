function Set-ContentDelivery {
    Write-Host "Setting Content Delivery"
    # ContentDeliveryManager controls Windows suggestions, sponsored apps, and lock screen ads.
    # Setting all these values to 0 stops Windows from silently installing apps and showing promotions.
    $key = 'HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\ContentDeliveryManager'
    $data = 0
    $values = @(
        'ContentDeliveryAllowed',
        'FeatureManagementEnabled',
        'SubscribedContentEnabled',
        'RemediationRequired',
        'OemPreInstalledAppsEnabled',
        'PreInstalledAppsEnabled',
        'PreInstalledAppsEverEnabled',
        'SilentInstalledAppsEnabled',
        'EnableAccountNotifications',
        'SubscribedContent-310093Enabled',
        'SubscribedContent-338393Enabled',
        'SubscribedContent-353694Enabled',
        'SubscribedContent-353696Enabled',
        'SubscribedContent-338388Enabled',
        'SubscribedContent-338387Enabled',
        'SubscribedContent-338389Enabled',
        'SystemPaneSuggestionsEnabled',
        'RotatingLockScreenOverlayEnabled',
        'SoftLandingEnabled'
    )

    $null = New-Item -Path $key -Force -ErrorAction SilentlyContinue
    foreach ($value in $values) {
        Set-ItemProperty -Path $key -Name $value -Value $data -Type DWord -Force
    }

    # This separate key controls account-related notifications in the Settings app
    $path = 'HKCU:\Software\Microsoft\Windows\CurrentVersion\SystemSettings\AccountNotifications'
    $null = New-Item -Path $path -Force -ErrorAction SilentlyContinue
    Set-ItemProperty -Path $path -Name 'EnableAccountNotifications' -Value 0 -Type DWord -Force
}

function Set-StorageSense {
    Write-Host "Setting Storage Sense"
    # StorageSense uses numeric value names as identifiers for each cleanup policy option.
    # Values set to 0 are disabled; values set to 1 or higher control cleanup intervals.
    $key = 'HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\StorageSense\Parameters\StoragePolicy'
    $null = New-Item -Path $key -Force -ErrorAction SilentlyContinue

    # Disable cleanup for: downloads (32), recycle bin (02), temp files (128), offline files (08), previous versions (256)
    foreach ($value in @('32', '02', '128', '08', '256')) {
        Set-ItemProperty -Path $key -Name $value -Value 0 -Type DWord -Force
    }
    Set-ItemProperty -Path $key -Name '01'   -Value 1  -Type DWord -Force  # Enable Storage Sense itself
    Set-ItemProperty -Path $key -Name '1024' -Value 1  -Type DWord -Force  # Run when low on disk space
    Set-ItemProperty -Path $key -Name '04'   -Value 1  -Type DWord -Force  # Delete temp files
    Set-ItemProperty -Path $key -Name '2048' -Value 30 -Type DWord -Force  # Keep files in recycle bin for 30 days
    # Run the cleanup task immediately so settings take effect without waiting for the next scheduled run
    Start-ScheduledTask -TaskPath '\Microsoft\Windows\DiskCleanup' -TaskName 'SilentCleanup'
}

function Set-DisableStorageSense {
    Write-Host "Disabling Storage Sense"
    # Reserved storage is disk space Windows sets aside for updates; freeing it saves space on small drives
    dism.exe /Online /Set-ReservedStorageState /State:Disabled
}

function Set-DisabledScheduledTasks {
    Write-Host "Disabling ScheduledTasks"
    # PcaPatchDbTask runs program compatibility scans after app installs; not needed on a clean system
    Disable-ScheduledTask -TaskPath '\Microsoft\Windows\Application Experience\' -TaskName 'PcaPatchDbTask'
    # UCPD velocity and UsageDataReporting send usage telemetry to Microsoft
    Disable-ScheduledTask -TaskPath '\Microsoft\Windows\AppxDeploymentClient\' -TaskName 'UCPD velocity' -ErrorAction SilentlyContinue
    Disable-ScheduledTask -TaskPath '\Microsoft\Windows\Flighting\FeatureConfig\' -TaskName 'UsageDataReporting' -ErrorAction SilentlyContinue
}

Export-ModuleMember -Function @()
