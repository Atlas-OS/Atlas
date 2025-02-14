# Add Music & Videos to Home (Fix missing folders in Quick Access)
function Add-MusicVideosToHome {
    $o = New-Object -ComObject shell.application
    $currentPins = $o.Namespace('shell:::{679f85cb-0220-4080-b29b-5540cc05aab6}').Items() | ForEach-Object { $_.Path }
    
    foreach ($path in @(
        [Environment]::GetFolderPath('MyVideos'),
        [Environment]::GetFolderPath('MyMusic')
    )) {
        if ($currentPins -notcontains $path) {
            $o.Namespace($path).Self.InvokeVerb('pintohome')
        }
    }
}

# Adds newUsers.ps1 script to RunOnce
function Add-NewUsersScript {
    reg add "HKCU\SOFTWARE\Microsoft\Windows\CurrentVersion\RunOnce" /v "RunScript" /t REG_SZ /d "powershell -EP Bypass -NoP & `"$([Environment]::GetFolderPath('Windows'))\AtlasModules\Scripts\newUsers.ps1`"" /f
}

# Configure OEM Information (AtlasOS branding)
function Set-OEMInformation {
    $version = "AtlasVersionUndefined"
    $reportedVer = "Atlas Playbook $version"

    bcdedit /set description "AtlasOS $(('10', '11')[[int]([System.Environment]::OSVersion.Version.Build -ge 22000)]) $version"

    Set-ItemProperty 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\OEMInformation' -Name 'Model' -Value $reportedVer -Force
    Set-ItemProperty 'HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion' -Name 'RegisteredOrganization' -Value $reportedVer -Force
    Set-ItemProperty 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\OEMInformation' -Name 'Manufacturer' -Value "Atlas Team" -Force
    Set-ItemProperty 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\OEMInformation' -Name 'SupportURL' -Value "https://discord.atlasos.net" -Force
    Set-ItemProperty 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\OEMInformation' -Name 'SupportPhone' -Value "https://github.com/Atlas-OS/Atlas" -Force
    Set-ItemProperty 'HKLM:\SOFTWARE\Atlas' -Name 'WinreFallbackFixed' -Value "1" -Force
}

# Configure Time Servers for better accuracy
function Set-TimeServers {
    Start-Service -Name "w32time" -ErrorAction SilentlyContinue
    w32tm /config /syncfromflags:manual /manualpeerlist:"0.pool.ntp.org 1.pool.ntp.org 2.pool.ntp.org 3.pool.ntp.org"
    w32tm /config /update
    w32tm /resync
}

# Create Shortcuts (Executes SHORTCUTS.ps1)
function New-Shortcuts {
    .\SHORTCUTS.ps1
}

# Delete Windows-version specific tweaks
function Remove-VersionSpecificTweaks {
    if ([System.Environment]::OSVersion.Version.Build -ge 22000) {
        Remove-Item -Path "$env:windir\AtlasDesktop\4. Interface Tweaks\File Explorer Customization\Folders in This PC" -Force -ErrorAction SilentlyContinue
        Remove-Item -Path "$env:windir\AtlasDesktop\4. Interface Tweaks\File Explorer Customization\Quick Access" -Force -ErrorAction SilentlyContinue
        Remove-Item -Path "$env:windir\AtlasDesktop\4. Interface Tweaks\Old Flyouts" -Force -ErrorAction SilentlyContinue
        Remove-Item -Path "$env:windir\AtlasDesktop\4. Interface Tweaks\Alt-Tab" -Force -ErrorAction SilentlyContinue
    } else {
        Remove-Item -Path "$env:windir\AtlasDesktop\3. General Configuration\Background Apps" -Force -ErrorAction SilentlyContinue
        Remove-Item -Path "$env:windir\AtlasModules\Tools\TimerResolution.exe" -Force -ErrorAction SilentlyContinue
    }
}

# Enable Notifications after disabling them earlier
function Enable-Notifications {
    Start-Process -FilePath "ENABLENOTIFS.cmd" -NoNewWindow -Wait
}

# Make MeasureSleep.exe run as admin
function Enable-MeasureSleepAdmin {
    Set-ItemProperty -Path 'HKLM:\Software\Microsoft\Windows NT\CurrentVersion\AppCompatFlags\Layers' `
        -Name "$([Environment]::GetFolderPath('Windows'))\AtlasDesktop\3. General Configuration\Timer Resolution\! MeasureSleep.exe" `
        -Value '~ RUNASADMIN' -Force
}

# Rebuild Performance Counters
function Reset-PerformanceCounters {
    lodctr /r
    lodctr /r
    winmgmt /resyncperf
}

function Invoke-AllMiscSystemUtilities {
    Add-MusicVideosToHome
    Add-NewUsersScript
    Set-OEMInformation
    Set-TimeServers
    New-Shortcuts
    Remove-VersionSpecificTweaks
    Enable-Notifications
    Enable-MeasureSleepAdmin
    Reset-PerformanceCounters
}
