# QOL domain functions: Shell

function Disable-ShowEdgeTabsInAltTab {
    # MultiTaskingAltTabFilter 3 means only show open windows, not browser tabs
    Set-ItemProperty -Path 'HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\Advanced' -Name 'MultiTaskingAltTabFilter' -Value 3 -Type DWord -Force
}

# Function to disable AutoRun

function Disable-AutoRun {
    # DisableAutoplay 1 stops the AutoPlay dialog from appearing when media is inserted
    $autoplayPath = 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\AutoplayHandlers'
    $null = New-Item -Path $autoplayPath -Force -ErrorAction SilentlyContinue
    Set-ItemProperty -Path $autoplayPath -Name 'DisableAutoplay' -Value 1 -Type DWord -Force

    # REG_NONE with empty data is how Windows stores 'take no action' autoplay choices
    $camPath = "$autoplayPath\EventHandlersDefaultSelection\CameraAlternate"
    $null = New-Item -Path $camPath -Force -ErrorAction SilentlyContinue
    Set-ItemProperty -Path $camPath -Name 'MSTakeNoAction' -Value ([byte[]]@()) -Type None -Force

    $storagePath = "$autoplayPath\EventHandlersDefaultSelection\StorageOnArrival"
    $null = New-Item -Path $storagePath -Force -ErrorAction SilentlyContinue
    Set-ItemProperty -Path $storagePath -Name 'MSTakeNoAction' -Value ([byte[]]@()) -Type None -Force

    $camChoicePath = "$autoplayPath\UserChosenExecuteHandlers\CameraAlternate\ShowPicturesOnArrival"
    $null = New-Item -Path $camChoicePath -Force -ErrorAction SilentlyContinue
    Set-ItemProperty -Path $camChoicePath -Name 'MSTakeNoAction' -Value ([byte[]]@()) -Type None -Force

    $storageChoicePath = "$autoplayPath\UserChosenExecuteHandlers\StorageOnArrival"
    $null = New-Item -Path $storageChoicePath -Force -ErrorAction SilentlyContinue
    Set-ItemProperty -Path $storageChoicePath -Name 'MSTakeNoAction' -Value ([byte[]]@()) -Type None -Force
}

# Function to disable Aero Shake

function Disable-AeroShake {
    # DisallowShaking 1 prevents shaking a window to minimize all others
    Set-ItemProperty -Path 'HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\Advanced' -Name 'DisallowShaking' -Value 1 -Type DWord -Force
}

# Function to disable low disk space checks

function Disable-LowDiskSpaceChecks {
    # Stops the low disk space balloon notification from appearing in the taskbar
    $null = New-Item -Path 'HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\Explorer' -Force -ErrorAction SilentlyContinue
    Set-ItemProperty -Path 'HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\Explorer' -Name 'NoLowDiskSpaceChecks' -Value 1 -Type DWord -Force
}

# Function to disable menu hover delay

function Disable-MenuHoverDelay {
    # MenuShowDelay is in milliseconds; 0 makes submenus open instantly on hover
    Set-ItemProperty -Path 'HKCU:\Control Panel\Desktop' -Name 'MenuShowDelay' -Value '0' -Type String -Force
}

# Function to disable shared experiences

function Disable-SharedExperiences {
    # NearShare is the Bluetooth file sharing feature; disabling it also stops CDP from running in the background
    $null = New-Item -Path 'HKCU:\Software\Microsoft\Windows\CurrentVersion\CDP\SettingsPage' -Force -ErrorAction SilentlyContinue
    Set-ItemProperty -Path 'HKCU:\Software\Microsoft\Windows\CurrentVersion\CDP\SettingsPage' -Name 'BluetoothLastDisabledNearShare' -Value 0 -Type DWord -Force

    $null = New-Item -Path 'HKCU:\Software\Microsoft\Windows\CurrentVersion\CDP' -Force -ErrorAction SilentlyContinue
    Set-ItemProperty -Path 'HKCU:\Software\Microsoft\Windows\CurrentVersion\CDP' -Name 'NearShareChannelUserAuthzPolicy' -Value 0 -Type DWord -Force
    # CdpSessionUserAuthzPolicy 1 keeps the device discoverable but blocks actual data sharing
    Set-ItemProperty -Path 'HKCU:\Software\Microsoft\Windows\CurrentVersion\CDP' -Name 'CdpSessionUserAuthzPolicy' -Value 1 -Type DWord -Force
}

# Function to disable recommendations in the Start Menu

function Disable-StartMenuRecommendations {
    # Hides the AI-powered recommendations and account notification banners in the Start Menu
    $path = 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced'
    Set-ItemProperty -Path $path -Name 'Start_IrisRecommendations' -Value 0 -Type DWord -Force
    Set-ItemProperty -Path $path -Name 'Start_AccountNotifications' -Value 0 -Type DWord -Force
}

# Function to restore old context menu in Windows 11

function Restore-OldContextMenu {
    & "$windir\AtlasDesktop\4. Interface Tweaks\Context Menus\Windows 11\Old Context Menu (default).cmd" /justcontext
}

# Function to set unpinned control center items

function Set-UnpinnedControlCenterItems {
    # Explorer must be restarted for Quick Action changes to take effect
    Stop-Process -Name explorer -Force

    $unpinnedPath = 'HKCU:\Control Panel\Quick Actions\Control Center\Unpinned'
    $capturePath  = 'HKCU:\Control Panel\Quick Actions\Control Center\QuickActionsStateCapture'
    $null = New-Item -Path $unpinnedPath -Force -ErrorAction SilentlyContinue
    $null = New-Item -Path $capturePath  -Force -ErrorAction SilentlyContinue

    # The available Quick Actions differ between Windows 10 and 11, so we branch by OS version
    if ((Get-CimInstance -ClassName Win32_OperatingSystem).Version -like '10.0.19045') {
        # Windows 10: unpin Connect, Location, and Screen Clipping buttons
        Set-ItemProperty -Path $unpinnedPath -Name 'Microsoft.QuickAction.Connect'       -Value ([byte[]]@()) -Type None -Force
        Set-ItemProperty -Path $unpinnedPath -Name 'Microsoft.QuickAction.Location'      -Value ([byte[]]@()) -Type None -Force
        Set-ItemProperty -Path $unpinnedPath -Name 'Microsoft.QuickAction.ScreenClipping' -Value ([byte[]]@()) -Type None -Force
        Set-ItemProperty -Path $capturePath  -Name 'Toggles' -Value 'Toggles,Microsoft.QuickAction.BlueLightReduction:false,Microsoft.QuickAction.AllSettings:false,Microsoft.QuickAction.Project:false' -Type String -Force
    } else {
        # Windows 11: unpin Cast and NearShare buttons
        Set-ItemProperty -Path $unpinnedPath -Name 'Microsoft.QuickAction.Cast'      -Value ([byte[]]@()) -Type None -Force
        Set-ItemProperty -Path $unpinnedPath -Name 'Microsoft.QuickAction.NearShare' -Value ([byte[]]@()) -Type None -Force
        Set-ItemProperty -Path $capturePath  -Name 'Toggles' -Value 'Toggles,Microsoft.QuickAction.BlueLightReduction:false,Microsoft.QuickAction.Accessibility:false,Microsoft.QuickAction.ProjectL2:false' -Type String -Force
    }

    Start-Process -FilePath explorer.exe
}

# Function to show more pins in the Start Menu

function Show-MorePinsInStartMenu {
    # Start_Layout 1 sets the Start Menu to show more pinned apps and fewer recommendations
    Set-ItemProperty -Path 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced' -Name 'Start_Layout' -Value 1 -Type DWord -Force
}

# Function to decrease shutdown time

function Show-CommandPromptOnWinX {
    # DontUsePowerShellOnWinX 1 replaces the PowerShell entries in Win+X with Command Prompt
    Set-ItemProperty -Path 'HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\Advanced' -Name 'DontUsePowerShellOnWinX' -Value 1 -Type DWord -Force
}

# Function to disable Microsoft Copilot
