# PowerShell Module: SystemOptimizationModule.psm1

# Function to add and set the Atlas themes by default
function Set-AtlasTheme {
    & "$windir\AtlasModules\initPowerShell.ps1"
    Set-Theme -Path "$([Environment]::GetFolderPath('Windows'))\Resources\Themes\atlas-v0.4.x-dark.theme"
    Set-ThemeMRU

    # Disable the Windows Spotlight overlay on the lock screen via machine policy
    $null = New-Item -Path 'HKLM:\SOFTWARE\Policies\Microsoft\Windows\Personalization' -Force -ErrorAction SilentlyContinue
    Set-ItemProperty -Path 'HKLM:\SOFTWARE\Policies\Microsoft\Windows\Personalization' -Name 'LockScreenOverlaysDisabled' -Value 1 -Type DWord -Force

    # Disable rotating lock screen images for this user
    $null = New-Item -Path 'HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\ContentDeliveryManager' -Force -ErrorAction SilentlyContinue
    Set-ItemProperty -Path 'HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\ContentDeliveryManager' -Name 'RotatingLockScreenEnabled' -Value 0 -Type DWord -Force

    # Also disable it on all LogonUI creative keys (covers per-session lock screen slots)
    foreach ($userKey in (Get-ChildItem "HKLM:SOFTWARE\Microsoft\Windows\CurrentVersion\Authentication\LogonUI\Creative").PsPath) {
        Set-ItemProperty -Path $userKey -Name 'RotatingLockScreenEnabled' -Type DWORD -Value 0 -Force
    }

    & "$windir\AtlasModules\initPowerShell.ps1"
    Set-LockscreenImage

    # Store literal %windir% so Windows expands it at runtime (same behavior as reg.exe REG_SZ)
    $null = New-Item -Path 'HKCU:\Software\Policies\Microsoft\Windows\Personalization' -Force -ErrorAction SilentlyContinue
    Set-ItemProperty -Path 'HKCU:\Software\Policies\Microsoft\Windows\Personalization' -Name 'ThemeFile' -Value '%windir%\Resources\Themes\atlas-v0.4.x-dark.theme' -Type String -Force
}

# Function to change the tooltip color to blue
function Set-TooltipColorBlue {
    # InfoWindow controls the background color of tooltip popups; value is R G B as a space-separated string
    $null = New-Item -Path 'HKCU:\Control Panel\Colors' -Force -ErrorAction SilentlyContinue
    Set-ItemProperty -Path 'HKCU:\Control Panel\Colors' -Name 'InfoWindow' -Value '246 253 255' -Type String -Force
}

# Function to disallow themes to change certain personalized features
function Disable-ThemeChangesToPersonalizedFeatures {
    # Prevents a theme switch from resetting the user's custom mouse pointers or desktop icons
    $path = 'HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Themes'
    $null = New-Item -Path $path -Force -ErrorAction SilentlyContinue
    Set-ItemProperty -Path $path -Name 'ThemeChangesMousePointers' -Value 0 -Type DWord -Force
    Set-ItemProperty -Path $path -Name 'ThemeChangesDesktopIcons' -Value 0 -Type DWord -Force
}

# Function to disable 'Always Read and Scan This Section'
function Disable-ReadAndScan {
    # selfscan and selfvoice are Ease of Access auto-scan settings that read UI aloud; rarely useful on desktop
    $path = 'HKCU:\SOFTWARE\Microsoft\Ease of Access'
    $null = New-Item -Path $path -Force -ErrorAction SilentlyContinue
    Set-ItemProperty -Path $path -Name 'selfscan' -Value 0 -Type DWord -Force
    Set-ItemProperty -Path $path -Name 'selfvoice' -Value 0 -Type DWord -Force
}

# Function to disable commonly annoying features and shortcuts
function Disable-AnnoyingFeaturesAndShortcuts {
    $accessBase = 'HKCU:\Control Panel\Accessibility'
    # Flags = '0' disables each accessibility feature; REG_SZ not DWord per Windows spec
    foreach ($sub in @('HighContrast', 'Keyboard Response', 'MouseKeys', 'StickyKeys', 'ToggleKeys')) {
        $null = New-Item -Path "$accessBase\$sub" -Force -ErrorAction SilentlyContinue
        Set-ItemProperty -Path "$accessBase\$sub" -Name 'Flags' -Value '0' -Type String -Force
    }

    # Key 00000104 is the Czech/Slovak layout hot key; removing the key disables the shortcut entirely
    Remove-Item -Path 'HKCU:\Control Panel\Input Method\Hot Keys\00000104' -Force -ErrorAction SilentlyContinue

    # Value '3' means no hotkey assigned for switching keyboard layouts or languages
    $togglePath = 'HKCU:\Keyboard Layout\Toggle'
    $null = New-Item -Path $togglePath -Force -ErrorAction SilentlyContinue
    Set-ItemProperty -Path $togglePath -Name 'Layout Hotkey' -Value '3' -Type String -Force
    Set-ItemProperty -Path $togglePath -Name 'Language Hotkey' -Value '3' -Type String -Force
    Set-ItemProperty -Path $togglePath -Name 'Hotkey' -Value '3' -Type String -Force

    # Stops the Win+Enter shortcut from launching Narrator
    $null = New-Item -Path 'HKCU:\Software\Microsoft\Narrator\NoRoam' -Force -ErrorAction SilentlyContinue
    Set-ItemProperty -Path 'HKCU:\Software\Microsoft\Narrator\NoRoam' -Name 'WinEnterLaunchEnabled' -Value 0 -Type DWord -Force
}

# Function to disable the accessibility tool shortcut
function Disable-AccessibilityToolShortcut {
    # LaunchAT 0 prevents the on-screen keyboard from launching on tablet sign-in
    $null = New-Item -Path 'HKCU:\Control Panel\Accessibility\SlateLaunch' -Force -ErrorAction SilentlyContinue
    Set-ItemProperty -Path 'HKCU:\Control Panel\Accessibility\SlateLaunch' -Name 'LaunchAT' -Value 0 -Type DWord -Force
}

# Function to disable Ease of Access sounds
function Disable-EaseOfAccessSounds {
    # Stop the beeps and tones that play when accessibility features activate
    $path = 'HKCU:\Control Panel\Accessibility'
    $null = New-Item -Path $path -Force -ErrorAction SilentlyContinue
    Set-ItemProperty -Path $path -Name 'Warning Sounds' -Value 0 -Type DWord -Force
    Set-ItemProperty -Path $path -Name 'Sound on Activation' -Value 0 -Type DWord -Force

    # WindowsEffect 0 means no visual flash substitute for system sounds
    $null = New-Item -Path "$path\SoundSentry" -Force -ErrorAction SilentlyContinue
    Set-ItemProperty -Path "$path\SoundSentry" -Name 'WindowsEffect' -Value '0' -Type String -Force
}

# Function to remove 'Extract' from context menu
function Remove-ExtractFromContextMenu {
    & "$windir\AtlasDesktop\4. Interface Tweaks\Context Menus\Extract\Remove Extract (default).cmd" /justcontext
}

# Function to remove printing from context menus
function Remove-PrintingFromContextMenus {
   & "$windir\AtlasDesktop\6. Advanced Configuration\Services\Printing\Disable Printing.cmd" /justcontext
}

# Function to show more details by default on file transfers
function Show-MoreDetailsOnTransfers {
    # EnthusiastMode 1 makes the copy/move dialog show detailed speed and time info by default
    $null = New-Item -Path 'HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\OperationStatusManager' -Force -ErrorAction SilentlyContinue
    Set-ItemProperty -Path 'HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\OperationStatusManager' -Name 'EnthusiastMode' -Value 1 -Type DWord -Force
}

# Function to debloat Send-To context menu
function Set-SendToContextMenu {
    & "$windir\AtlasDesktop\4. Interface Tweaks\Context Menus\Send To\Debloat Send To Context Menu.cmd" -Disable @('Documents', 'Mail Recipient', 'Fax recipient', 'Bluetooth')
}

# Function to disable use of check boxes to select items
function Disable-UseCheckBoxesToSelectItems {
    # AutoCheckSelect 0 removes the checkboxes that appear on hover in File Explorer
    Set-ItemProperty -Path 'HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\Advanced' -Name 'AutoCheckSelect' -Value 0 -Type DWord -Force
}

# Function to hide Gallery in File Explorer
function Hide-GalleryInFileExplorer {
    & "$windir\AtlasDesktop\4. Interface Tweaks\File Explorer Customization\Gallery\Disable Gallery (default).cmd" /justcontext
}

# Function to disable searching for invalid shortcuts
function Disable-SearchingForInvalidShortcuts {
    # NoResolveSearch and NoResolveTrack stop Explorer from hunting for moved files when a shortcut breaks
    $path = 'HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\Explorer'
    $null = New-Item -Path $path -Force -ErrorAction SilentlyContinue
    Set-ItemProperty -Path $path -Name 'NoResolveSearch' -Value 1 -Type DWord -Force
    Set-ItemProperty -Path $path -Name 'NoResolveTrack' -Value 1 -Type DWord -Force
}

# Function to disable network navigation pane in Explorer
function Disable-NetworkNavigationPaneInExplorer {
    & "$windir\AtlasDesktop\3. General Configuration\File Sharing\Network Navigation Pane\Disable Network Navigation Pane (default).cmd" /justcontext
}

# Function to not show Office files in Quick Access
function Hide-OfficeFilesInQuickAccess {
    # ShowCloudFilesInQuickAccess 0 hides OneDrive and SharePoint files from the Quick Access sidebar
    Set-ItemProperty -Path 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer' -Name 'ShowCloudFilesInQuickAccess' -Value 0 -Type DWord -Force
}

# Function to always show the full context menu on items
function Show-FullContextMenuOnItems {
    # MultipleInvokePromptMinimum controls how many files trigger the 'are you sure?' prompt; 100 means never prompt
    Set-ItemProperty -Path 'HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer' -Name 'MultipleInvokePromptMinimum' -Value 100 -Type DWord -Force
}

# Function to hide recent items in Quick Access
function Hide-RecentItems {
    # Stop Explorer from tracking and showing recently opened files
    $explorerPath = 'HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer'
    Set-ItemProperty -Path $explorerPath -Name 'ShowFrequent' -Value 0 -Type DWord -Force
    Set-ItemProperty -Path $explorerPath -Name 'ShowRecent' -Value 0 -Type DWord -Force
    Set-ItemProperty -Path "$explorerPath\Advanced" -Name 'Start_TrackDocs' -Value 0 -Type DWord -Force

    # Policy keys enforce the setting so it cannot be toggled back in Folder Options
    $policyPath = 'HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\Explorer'
    $null = New-Item -Path $policyPath -Force -ErrorAction SilentlyContinue
    Set-ItemProperty -Path $policyPath -Name 'ClearRecentDocsOnExit' -Value 1 -Type DWord -Force
    Set-ItemProperty -Path $policyPath -Name 'NoRecentDocsHistory' -Value 1 -Type DWord -Force

    # NoRemoteDestinations stops apps from adding entries to the Jump List / recent files list
    $null = New-Item -Path 'HKCU:\SOFTWARE\Policies\Microsoft\Windows\Explorer' -Force -ErrorAction SilentlyContinue
    Set-ItemProperty -Path 'HKCU:\SOFTWARE\Policies\Microsoft\Windows\Explorer' -Name 'NoRemoteDestinations' -Value 1 -Type DWord -Force
}

# Function to minimize mouse hover time for item info
function Set-MouseHoverTimeForItemInfo {
    # MouseHoverTime is in milliseconds; 20ms means tooltips appear almost instantly
    Set-ItemProperty -Path 'HKCU:\Control Panel\Desktop' -Name 'MouseHoverTime' -Value '20' -Type String -Force
}

# Function to configure File Explorer to open to This PC
function Set-FileExplorerToThisPC {
    # LaunchTo 1 means open to This PC; 2 would be Quick Access (Windows default)
    Set-ItemProperty -Path 'HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\Advanced' -Name 'LaunchTo' -Value 1 -Type DWord -Force
}

# Function to remove previous versions from Explorer
function Remove-PreviousVersionsFromExplorer {
    # Removes the Previous Versions tab from file properties; Shadow Copy is not used on Atlas
    Remove-ItemProperty -Path 'HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer' -Name 'NoPreviousVersionsPage' -Force -ErrorAction SilentlyContinue
    Remove-ItemProperty -Path 'HKCU:\SOFTWARE\Policies\Microsoft\PreviousVersions' -Name 'DisableLocalPage' -Force -ErrorAction SilentlyContinue
}

# Function to remove shortcut text
function Remove-ShortcutText {
    # ShortcutNameTemplate with "%s.lnk" keeps the original name without adding "- Shortcut" suffix
    $null = New-Item -Path 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\NamingTemplates' -Force -ErrorAction SilentlyContinue
    Set-ItemProperty -Path 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\NamingTemplates' -Name 'ShortcutNameTemplate' -Value '"%s.lnk"' -Type String -Force
}

# Function to configure Explorer to show all files with file extensions
function Show-AllFilesWithExtensions {
    # Hidden 1 shows hidden files; HideFileExt 0 shows file extensions for all file types
    $path = 'HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\Advanced'
    Set-ItemProperty -Path $path -Name 'Hidden' -Value 1 -Type DWord -Force
    Set-ItemProperty -Path $path -Name 'HideFileExt' -Value 0 -Type DWord -Force
}

# Function to use compact mode in File Explorer
function Enable-CompactMode {
    # UseCompactMode 1 reduces row height in File Explorer, fitting more items on screen
    Set-ItemProperty -Path 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced' -Name 'UseCompactMode' -Value 1 -Type DWord -Force
}

# Function to not show Edge tabs in Alt-Tab
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
function Show-CommandPromptOnWinX {
    # DontUsePowerShellOnWinX 1 replaces the PowerShell entries in Win+X with Command Prompt
    Set-ItemProperty -Path 'HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\Advanced' -Name 'DontUsePowerShellOnWinX' -Value 1 -Type DWord -Force
}

# Function to disable Microsoft Copilot
function Disable-MicrosoftCopilot {
    # Policy key is required; the user-facing toggle alone does not survive updates
    $null = New-Item -Path 'HKCU:\Software\Policies\Microsoft\Windows\WindowsCopilot' -Force -ErrorAction SilentlyContinue
    Set-ItemProperty -Path 'HKCU:\Software\Policies\Microsoft\Windows\WindowsCopilot' -Name 'TurnOffWindowsCopilot' -Value 1 -Type DWord -Force
}

# Function to disable Show Desktop peek on taskbar
function Disable-ShowDesktopPeek {
    # DisablePreviewDesktop 1 disables the transparent preview when hovering over the Show Desktop button
    Set-ItemProperty -Path 'HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\Advanced' -Name 'DisablePreviewDesktop' -Value 1 -Type DWord -Force
}

# Function to never use tablet mode
function Hide-TabletMode {
    # SignInMode 1 forces desktop mode at sign-in regardless of whether a keyboard is attached
    $null = New-Item -Path 'HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\ImmersiveShell' -Force -ErrorAction SilentlyContinue
    Set-ItemProperty -Path 'HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\ImmersiveShell' -Name 'SignInMode' -Value 1 -Type DWord -Force
}

# Function to disable Windows Chat
function Disable-WindowsChat {
    # ChatIcon 3 hides the Teams/Chat icon; policy key enforces it so it does not reappear after updates
    $null = New-Item -Path 'HKLM:\SOFTWARE\Policies\Microsoft\Windows\Windows Chat' -Force -ErrorAction SilentlyContinue
    Set-ItemProperty -Path 'HKLM:\SOFTWARE\Policies\Microsoft\Windows\Windows Chat' -Name 'ChatIcon' -Value 3 -Type DWord -Force
    Set-ItemProperty -Path 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced' -Name 'TaskbarMn' -Value 0 -Type DWord -Force
}

# Function to add 'End task' to the taskbar
function Add-EndTaskToTaskbar {
    # TaskbarEndTask 1 adds a right-click 'End task' option directly on running apps in the taskbar
    $null = New-Item -Path 'HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\Advanced\TaskbarDeveloperSettings' -Force -ErrorAction SilentlyContinue
    Set-ItemProperty -Path 'HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\Advanced\TaskbarDeveloperSettings' -Name 'TaskbarEndTask' -Value 1 -Type DWord -Force
}

# Function to disable Task View on taskbar
function Disable-TaskViewOnTaskbar {
    # Remove the Enabled value first; if it stays set it can override ShowTaskViewButton
    Remove-ItemProperty -Path 'HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\MultiTaskingView\AllUpView' -Name 'Enabled' -Force -ErrorAction SilentlyContinue
    Set-ItemProperty -Path 'HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\Advanced' -Name 'ShowTaskViewButton' -Value 0 -Type DWord -Force
}

# Function to set taskbar alignment to left
function Set-TaskbarAlignLeft {
    # TaskbarAl 0 moves the taskbar icons to the left; 1 is the Windows 11 centered default
    Set-ItemProperty -Path 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced' -Name 'TaskbarAl' -Value 0 -Type DWord -Force
}

# Function to add network sharing shortcut
function Add-NetworkSharingShortcut {
    & "$windir\AtlasModules\initPowerShell.ps1"
    New-Shortcut -Source 'control.exe' `
        -Destination "$([Environment]::GetFolderPath('Windows'))\AtlasDesktop\3. General Configuration\File Sharing\Sharing Settings.lnk" `
        -Arguments '/name Microsoft.NetworkAndSharingCenter /page Advanced'
}

# Function to configure boot configuration
function Set-BootConfiguration {
    # Set boot menu timeout to 10 seconds and use the legacy (text-based) boot menu
    & bcdedit /timeout 10
    & bcdedit /set bootmenupolicy legacy
}

# Function to disable wallpaper compression
function Disable-WallpaperCompression {
    # JPEGImportQuality 100 stops Windows from re-compressing wallpapers when applying them
    Set-ItemProperty -Path 'HKCU:\Control Panel\Desktop' -Name 'JPEGImportQuality' -Value 100 -Type DWord -Force
}

# Function to configure Start Menu
function Set-StartMenu {
    # ConfigureStartPins is a JSON payload that defines which apps are pinned in the Start Menu
    $null = New-Item -Path 'HKLM:\SOFTWARE\Microsoft\PolicyManager\current\device\Start' -Force -ErrorAction SilentlyContinue
    Set-ItemProperty -Path 'HKLM:\SOFTWARE\Microsoft\PolicyManager\current\device\Start' -Name 'ConfigureStartPins' -Type String -Force `
        -Value '{"pinnedList":[{"packagedAppId":"windows.immersivecontrolpanel_cw5n1h2txyewy!microsoft.windows.immersivecontrolpanel"},{"packagedAppId":"Microsoft.WindowsTerminal_8wekyb3d8bbwe!App"},{"desktopAppLink":"%APPDATA%\\Microsoft\\Windows\\Start Menu\\Programs\\File Explorer.lnk"},{"packagedAppId":"Microsoft.WindowsStore_8wekyb3d8bbwe!App"},{"packagedAppId":"Microsoft.GamingApp_8wekyb3d8bbwe!Microsoft.Xbox.App"},{"packagedAppId":"Microsoft.WindowsCalculator_8wekyb3d8bbwe!App"},{"packagedAppId":"Microsoft.WindowsNotepad_8wekyb3d8bbwe!App"},{"packagedAppId":"Microsoft.Paint_8wekyb3d8bbwe!App"},{"packagedAppId":"Microsoft.SecHealthUI_8wekyb3d8bbwe!SecHealthUI"}]}'

    foreach ($userKey in (Get-RegUserPaths).PsPath) {
        $default = if ($userKey -match 'AME_UserHive_Default') { $true }
        $sid = Split-Path $userKey -Leaf

        # Get Local AppData path; default hive uses a GUID-based lookup, loaded hives use Shell Folders
        $appData = if ($default) {
            Get-UserPath -Folder 'F1B32785-6FBA-4FCF-9D55-7B8E7F157091'
        } else {
            (Get-ItemProperty "$userKey\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\Shell Folders" -Name 'Local AppData' -ErrorAction SilentlyContinue).'Local AppData'
        }

        Write-Title "Configuring Start Menu for '$sid'..."
        if ([string]::IsNullOrEmpty($appData) -or !(Test-Path $appData)) {
            Write-Error "Couldn't find AppData value for $sid!"
        } else {
            Write-Output "Copying default layout XML"
            Copy-Item -Path "$windir\AtlasModules\Other\Layout.xml" -Destination "$appdata\Microsoft\Windows\Shell\LayoutModification.xml" -Force

            if (!$default) {
                Write-Output "Clearing Start Menu pinned items"
                # Remove the binary .bin files that cache the current pinned layout; Windows recreates them on next login
                $packages = Get-ChildItem -Path "$appdata\Packages" -Directory | Where-Object { $_.Name -match "Microsoft.Windows.StartMenuExperienceHost" }
                foreach ($package in $packages) {
                    $bins = Get-ChildItem -Path "$appdata\Packages\$($package.Name)\LocalState" -File | Where-Object { $_.Name -like "start*.bin" }
                    foreach ($bin in $bins.FullName) {
                        Remove-Item -Path $bin -Force
                    }
                }
            }
        }

        if (!$default) {
            Write-Output "Clearing default 'tilegrid'"
            # The tilegrid cache stores the tile layout; removing it forces the Start Menu to rebuild from the XML
            $tilegrid = Get-ChildItem -Path "$userKey\SOFTWARE\Microsoft\Windows\CurrentVersion\CloudStore\Store\Cache\DefaultAccount" -Recurse | Where-Object { $_.Name -match "start.tilegrid" }
            foreach ($key in $tilegrid) {
                Remove-Item -Path $key.PSPath -Force
            }
        }

        Write-Output "Removing advertisements/stubs from Start Menu (23H2+)"
        Remove-ItemProperty -Path "$userKey\SOFTWARE\Microsoft\Windows\CurrentVersion\Start" -Name 'Config' -Force -ErrorAction SilentlyContinue
    }
    Remove-AppxPackage -Package 'Microsoft.Windows.StartMenuExperienceHost*'

    # Hide most-used apps list and recently added apps from the Start Menu via policy
    $explorerPoliciesPath = 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\Explorer'
    $null = New-Item -Path $explorerPoliciesPath -Force -ErrorAction SilentlyContinue
    Set-ItemProperty -Path $explorerPoliciesPath -Name 'NoStartMenuMFUprogramsList' -Value 1 -Type DWord -Force

    $winExplorerPath = 'HKLM:\SOFTWARE\Policies\Microsoft\Windows\Explorer'
    $null = New-Item -Path $winExplorerPath -Force -ErrorAction SilentlyContinue
    # ShowOrHideMostUsedApps 2 hides the most-used apps section
    Set-ItemProperty -Path $winExplorerPath -Name 'ShowOrHideMostUsedApps'          -Value 2 -Type DWord -Force
    Set-ItemProperty -Path $winExplorerPath -Name 'HideRecentlyAddedApps'           -Value 1 -Type DWord -Force
    Set-ItemProperty -Path $winExplorerPath -Name 'HideRecommendedPersonalizedSites' -Value 1 -Type DWord -Force
}

# Function to configure Windows Ink Workspace
function Set-WindowsInkWorkspace {
    # Stops the Ink Workspace from showing app suggestions (ads) on the pen menu
    $null = New-Item -Path 'HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\PenWorkspace' -Force -ErrorAction SilentlyContinue
    Set-ItemProperty -Path 'HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\PenWorkspace' -Name 'PenWorkspaceAppSuggestionsEnabled' -Value 0 -Type DWord -Force
}

# Function to disable automatic Store app archiving
function Disable-AutomaticStoreAppArchiving {
    & "$windir\AtlasDesktop\3. General Configuration\Store App Archiving\Disable Store App Archiving (default).cmd" /justcontext
}

# Function to disable dynamic lighting
function Disable-DynamicLighting {
    # AmbientLightingEnabled 0 stops Windows from controlling RGB lighting on supported peripherals
    $null = New-Item -Path 'HKCU:\Software\Microsoft\Lighting' -Force -ErrorAction SilentlyContinue
    Set-ItemProperty -Path 'HKCU:\Software\Microsoft\Lighting' -Name 'AmbientLightingEnabled' -Value 0 -Type DWord -Force
}

# Function to disable mouse acceleration
function Disable-MouseAcceleration {
    # MouseSpeed 0 disables pointer precision; Threshold values must also be 0 to fully remove the acceleration curve
    $path = 'HKCU:\Control Panel\Mouse'
    Set-ItemProperty -Path $path -Name 'MouseSpeed'      -Value '0' -Type String -Force
    Set-ItemProperty -Path $path -Name 'MouseThreshold1' -Value '0' -Type String -Force
    Set-ItemProperty -Path $path -Name 'MouseThreshold2' -Value '0' -Type String -Force
}

# Function to disable screen capture hotkey
function Disable-ScreenCaptureHotkey {
    # PrintScreenKeyForSnippingEnabled 0 stops Print Screen from opening Snipping Tool
    $null = New-Item -Path 'HKCU:\Control Panel\Keyboard' -Force -ErrorAction SilentlyContinue
    Set-ItemProperty -Path 'HKCU:\Control Panel\Keyboard' -Name 'PrintScreenKeyForSnippingEnabled' -Value 0 -Type DWord -Force
}

# Function to disable spell checking
function Disable-SpellChecking {
    # All five values must be set to 0 to fully disable autocorrect and prediction on the touch keyboard
    $path = 'HKCU:\SOFTWARE\Microsoft\TabletTip\1.7'
    $null = New-Item -Path $path -Force -ErrorAction SilentlyContinue
    Set-ItemProperty -Path $path -Name 'EnableAutocorrection'          -Value 0 -Type DWord -Force
    Set-ItemProperty -Path $path -Name 'EnableDoubleTapSpace'          -Value 0 -Type DWord -Force
    Set-ItemProperty -Path $path -Name 'EnablePredictionSpaceInsertion' -Value 0 -Type DWord -Force
    Set-ItemProperty -Path $path -Name 'EnableSpellchecking'           -Value 0 -Type DWord -Force
    Set-ItemProperty -Path $path -Name 'EnableTextPrediction'          -Value 0 -Type DWord -Force
}

# Function to disable unnecessary touch keyboard settings
function Disable-UnnecessaryTouchKeyboardSettings {
    # EnableAutoShiftEngage auto-capitalizes after a period; EnableKeyAudioFeedback plays click sounds
    $path = 'HKCU:\SOFTWARE\Microsoft\TabletTip\1.7'
    $null = New-Item -Path $path -Force -ErrorAction SilentlyContinue
    Set-ItemProperty -Path $path -Name 'EnableAutoShiftEngage'  -Value 0 -Type DWord -Force
    Set-ItemProperty -Path $path -Name 'EnableKeyAudioFeedback' -Value 0 -Type DWord -Force
}

# Function to disable touch visual feedback
function Disable-TouchVisualFeedback {
    # Removes the visual circles that appear on screen when touching with fingers
    $path = 'HKCU:\Control Panel\Cursors'
    Set-ItemProperty -Path $path -Name 'GestureVisualization' -Value 0 -Type DWord -Force
    Set-ItemProperty -Path $path -Name 'ContactVisualization' -Value 0 -Type DWord -Force
}

# Function to disable Windows Feedback
function Disable-WindowsFeedback {
    # NumberOfSIUFInPeriod 0 stops Windows from prompting for feedback; PeriodInNanoSeconds is removed so there is no reset window
    $path = 'HKCU:\SOFTWARE\Microsoft\Siuf\Rules'
    $null = New-Item -Path $path -Force -ErrorAction SilentlyContinue
    Set-ItemProperty -Path $path -Name 'NumberOfSIUFInPeriod' -Value 0 -Type DWord -Force
    Remove-ItemProperty -Path $path -Name 'PeriodInNanoSeconds' -Force -ErrorAction SilentlyContinue

    # Machine policy prevents the feedback hub from being re-enabled by Windows Update
    $null = New-Item -Path 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\DataCollection' -Force -ErrorAction SilentlyContinue
    Set-ItemProperty -Path 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\DataCollection' -Name 'DoNotShowFeedbackNotifications' -Value 1 -Type DWord -Force
}

# Function to disable Windows Spotlight
function Disable-WindowsSpotlight {
    # Disables all Spotlight features: lock screen images, welcome experience, action center tips, and third-party suggestions
    $path = 'HKCU:\SOFTWARE\Policies\Microsoft\Windows\CloudContent'
    $null = New-Item -Path $path -Force -ErrorAction SilentlyContinue
    Set-ItemProperty -Path $path -Name 'DisableWindowsSpotlightFeatures'                 -Value 1 -Type DWord -Force
    Set-ItemProperty -Path $path -Name 'DisableWindowsSpotlightWindowsWelcomeExperience' -Value 1 -Type DWord -Force
    Set-ItemProperty -Path $path -Name 'DisableWindowsSpotlightOnActionCenter'           -Value 1 -Type DWord -Force
    Set-ItemProperty -Path $path -Name 'DisableWindowsSpotlightOnSettings'               -Value 1 -Type DWord -Force
    Set-ItemProperty -Path $path -Name 'DisableThirdPartySuggestions'                    -Value 1 -Type DWord -Force

    # Also hide the Spotlight desktop icon (the info button that appears on the wallpaper)
    $null = New-Item -Path 'HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\HideDesktopIcons\NewStartPanelt' -Force -ErrorAction SilentlyContinue
    Set-ItemProperty -Path 'HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\HideDesktopIcons\NewStartPanelt' -Name '{2cc5ca98-6485-489a-920e-b3e88a6ccce3}' -Value 1 -Type DWord -Force
}

# Function to not reduce sounds while in a call
function Disable-ReduceSoundsWhileInCall {
    # UserDuckingPreference 3 disables the automatic volume reduction Windows applies during calls
    $null = New-Item -Path 'HKCU:\SOFTWARE\Microsoft\Multimedia\Audio' -Force -ErrorAction SilentlyContinue
    Set-ItemProperty -Path 'HKCU:\SOFTWARE\Microsoft\Multimedia\Audio' -Name 'UserDuckingPreference' -Value 3 -Type DWord -Force
}

# Function to hide disabled and disconnected devices in sounds panel
function Hide-DisabledAndDisconnectedDevicesInSoundsPanel {
    # Cleans up the Sound control panel by hiding devices that are not actively connected
    $path = 'HKCU:\SOFTWARE\Microsoft\Multimedia\Audio\DeviceCpl'
    $null = New-Item -Path $path -Force -ErrorAction SilentlyContinue
    Set-ItemProperty -Path $path -Name 'ShowDisconnectedDevices' -Value 0 -Type DWord -Force
    Set-ItemProperty -Path $path -Name 'ShowHiddenDevices'       -Value 0 -Type DWord -Force
}

# Function to configure visual effects
function Set-VisualEffects {
    $desktopPath = 'HKCU:\Control Panel\Desktop'
    # FontSmoothing 2 enables ClearType
    Set-ItemProperty -Path $desktopPath -Name 'FontSmoothing'        -Value '2' -Type String -Force
    # UserPreferencesMask is a bitmask; this value enables font smoothing and drop shadows while disabling animations
    Set-ItemProperty -Path $desktopPath -Name 'UserPreferencesMask'  -Value ([byte[]](0x90, 0x12, 0x03, 0x80, 0x10, 0x00, 0x00, 0x00)) -Type Binary -Force
    # DragFullWindows 1 shows window contents while dragging instead of an outline
    Set-ItemProperty -Path $desktopPath -Name 'DragFullWindows'      -Value '1' -Type String -Force

    # MinAnimate 0 disables the minimize/maximize animation for windows
    $null = New-Item -Path "$desktopPath\WindowMetrics" -Force -ErrorAction SilentlyContinue
    Set-ItemProperty -Path "$desktopPath\WindowMetrics" -Name 'MinAnimate' -Value '0' -Type String -Force

    $advPath = 'HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\Advanced'
    Set-ItemProperty -Path $advPath -Name 'ListviewAlphaSelect' -Value 1 -Type DWord -Force  # Translucent selection rectangle
    Set-ItemProperty -Path $advPath -Name 'IconsOnly'           -Value 0 -Type DWord -Force  # Show thumbnails not icons
    Set-ItemProperty -Path $advPath -Name 'TaskbarAnimations'   -Value 0 -Type DWord -Force  # Disable taskbar animations
    Set-ItemProperty -Path $advPath -Name 'ListviewShadow'      -Value 1 -Type DWord -Force  # Drop shadow on icon labels

    # VisualFXSetting 3 means custom; required so Windows respects the individual settings above
    $null = New-Item -Path 'HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\VisualEffects' -Force -ErrorAction SilentlyContinue
    Set-ItemProperty -Path 'HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\VisualEffects' -Name 'VisualFXSetting' -Value 3 -Type DWord -Force

    # Disable Aero Peek and thumbnail hibernation from the DWM (Desktop Window Manager)
    $null = New-Item -Path 'HKCU:\SOFTWARE\Microsoft\Windows\DWM' -Force -ErrorAction SilentlyContinue
    Set-ItemProperty -Path 'HKCU:\SOFTWARE\Microsoft\Windows\DWM' -Name 'EnableAeroPeek'          -Value 0 -Type DWord -Force
    Set-ItemProperty -Path 'HKCU:\SOFTWARE\Microsoft\Windows\DWM' -Name 'AlwaysHibernateThumbnails' -Value 0 -Type DWord -Force
}

Export-ModuleMember -Function @()
