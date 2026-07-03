# QOL domain functions: StartupShutdown

function Set-ShutdownTime {
    # How long Windows waits before force-killing a hung app or service on shutdown (in milliseconds)
    $desktopPath = 'HKCU:\Control Panel\Desktop'
    Set-ItemProperty -Path $desktopPath -Name 'HungAppTimeout'      -Value '2000' -Type String -Force
    Set-ItemProperty -Path $desktopPath -Name 'WaitToKillAppTimeOut' -Value '2000' -Type String -Force

    $null = New-Item -Path 'HKLM:\SYSTEM\CurrentControlSet\Control' -Force -ErrorAction SilentlyContinue
    Set-ItemProperty -Path 'HKLM:\SYSTEM\CurrentControlSet\Control' -Name 'WaitToKillServiceTimeout' -Value '2000' -Type String -Force
}

# Function to disable startup delay

function Disable-StartupDelay {
    # StartupDelayInMSec 0 removes the artificial 10-second delay Explorer adds before launching startup apps
    $null = New-Item -Path 'HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\Serialize' -Force -ErrorAction SilentlyContinue
    Set-ItemProperty -Path 'HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\Serialize' -Name 'StartupDelayInMSec' -Value 0 -Type DWord -Force
}

# Function to force close applications on session end

function Set-CloseApplicationsOnSessionEnd {
    # AutoEndTasks 1 tells Windows to kill apps that do not respond to WM_QUERYENDSESSION instead of showing a dialog
    Set-ItemProperty -Path 'HKCU:\Control Panel\Desktop' -Name 'AutoEndTasks' -Value '1' -Type String -Force
}

# Function to show Command Prompt on Win+X
