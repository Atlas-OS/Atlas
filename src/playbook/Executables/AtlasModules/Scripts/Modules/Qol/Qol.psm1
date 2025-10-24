# PowerShell Module: SystemOptimizationModule.psm1

# Function to add and set the Atlas themes by default
function Set-AtlasTheme {
    & "$windir\AtlasModules\initPowerShell.ps1"
    Set-Theme -Path "$([Environment]::GetFolderPath('Windows'))\Resources\Themes\atlas-v0.4.x-dark.theme"
    Set-ThemeMRU

    reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows\Personalization" /v "LockScreenOverlaysDisabled" /t REG_DWORD /d 1 /f
    reg add "HKCU\SOFTWARE\Microsoft\Windows\CurrentVersion\ContentDeliveryManager" /v "RotatingLockScreenEnabled" /t REG_DWORD /d 0 /f

    foreach ($userKey in (Get-ChildItem "HKLM:SOFTWARE\Microsoft\Windows\CurrentVersion\Authentication\LogonUI\Creative").PsPath) {
        Set-ItemProperty -Path $userKey -Name 'RotatingLockScreenEnabled' -Type DWORD -Value 0 -Force
    }

    & "$windir\AtlasModules\initPowerShell.ps1"
    Set-LockscreenImage

    reg add "HKCU\Software\Policies\Microsoft\Windows\Personalization" /v "ThemeFile" /t REG_SZ /d "%windir%\Resources\Themes\atlas-v0.4.x-dark.theme" /f
}

# Function to change the tooltip color to blue
function Set-TooltipColorBlue {
    reg add "HKCU\Control Panel\Colors" /v "InfoWindow" /t REG_SZ /d "246 253 255" /f
}

# Function to disallow themes to change certain personalized features
function Disable-ThemeChangesToPersonalizedFeatures {
    reg add "HKCU\SOFTWARE\Microsoft\Windows\CurrentVersion\Themes" /v "ThemeChangesMousePointers" /t REG_DWORD /d 0 /f
    reg add "HKCU\SOFTWARE\Microsoft\Windows\CurrentVersion\Themes" /v "ThemeChangesDesktopIcons" /t REG_DWORD /d 0 /f
}

# Function to disable 'Always Read and Scan This Section'
function Disable-ReadAndScan {
    reg add "HKCU\SOFTWARE\Microsoft\Ease of Access" /v "selfscan" /t REG_DWORD /d 0 /f
    reg add "HKCU\SOFTWARE\Microsoft\Ease of Access" /v "selfvoice" /t REG_DWORD /d 0 /f
}

# Function to disable commonly annoying features and shortcuts
function Disable-AnnoyingFeaturesAndShortcuts {
    reg add "HKCU\Control Panel\Accessibility\HighContrast" /v "Flags" /t REG_DWORD /d 0 /f
    reg add "HKCU\Control Panel\Accessibility\Keyboard Response" /v "Flags" /t REG_DWORD /d 0 /f
    reg add "HKCU\Control Panel\Accessibility\MouseKeys" /v "Flags" /t REG_DWORD /d 0 /f
    reg add "HKCU\Control Panel\Accessibility\StickyKeys" /v "Flags" /t REG_DWORD /d 0 /f
    reg add "HKCU\Control Panel\Accessibility\ToggleKeys" /v "Flags" /t REG_DWORD /d 0 /f

    reg delete "HKCU\Control Panel\Input Method\Hot Keys\00000104" /f
    reg add "HKCU\Keyboard Layout\Toggle" /v "Layout Hotkey" /t REG_DWORD /d 3 /f
    reg add "HKCU\Keyboard Layout\Toggle" /v "Language Hotkey" /t REG_DWORD /d 3 /f
    reg add "HKCU\Keyboard Layout\Toggle" /v "Hotkey" /t REG_DWORD /d 3 /f

    reg add "HKCU\Software\Microsoft\Narrator\NoRoam" /v "WinEnterLaunchEnabled" /t REG_DWORD /d 0 /f
}

# Function to disable the accessibility tool shortcut
function Disable-AccessibilityToolShortcut {
    reg add "HKCU\Control Panel\Accessibility\SlateLaunch" /v "LaunchAT" /t REG_DWORD /d 0 /f
}

# Function to disable Ease of Access sounds
function Disable-EaseOfAccessSounds {
    reg add "HKCU\Control Panel\Accessibility" /v "Warning Sounds" /t REG_DWORD /d 0 /f
    reg add "HKCU\Control Panel\Accessibility" /v "Sound on Activation" /t REG_DWORD /d 0 /f
    reg add "HKCU\Control Panel\Accessibility\SoundSentry" /v "WindowsEffect" /t REG_SZ /d "0" /f
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
    reg add "HKCU\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\OperationStatusManager" /v "EnthusiastMode" /t REG_DWORD /d 1 /f
}
# Function to debloat Send-To context menu
function Set-SendToContextMenu {
    & "$windir\AtlasDesktop\4. Interface Tweaks\Context Menus\Send To\Debloat Send To Context Menu.cmd" -Disable @('Documents', 'Mail Recipient', 'Fax recipient', 'Bluetooth')
}

# Function to disable use of check boxes to select items
function Disable-UseCheckBoxesToSelectItems {
    reg add "HKCU\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\Advanced" /v "AutoCheckSelect" /t REG_DWORD /d 0 /f
}

# Function to hide Gallery in File Explorer
function Hide-GalleryInFileExplorer {
    & "$windir\AtlasDesktop\4. Interface Tweaks\File Explorer Customization\Gallery\Disable Gallery (default).cmd" /justcontext
}

# Function to disable searching for invalid shortcuts
function Disable-SearchingForInvalidShortcuts {
    reg add "HKCU\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\Explorer" /v "NoResolveSearch" /t REG_DWORD /d 1 /f
    reg add "HKCU\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\Explorer" /v "NoResolveTrack" /t REG_DWORD /d 1 /f
}

# Function to disable network navigation pane in Explorer
function Disable-NetworkNavigationPaneInExplorer {
    & "$windir\AtlasDesktop\3. General Configuration\File Sharing\Network Navigation Pane\Disable Network Navigation Pane (default).cmd" /justcontext
}

# Function to not show Office files in Quick Access
function Hide-OfficeFilesInQuickAccess {
    reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\Explorer" /v "ShowCloudFilesInQuickAccess" /t REG_DWORD /d 0 /f
}
# Function to always show the full context menu on items
function Show-FullContextMenuOnItems {
    reg add "HKCU\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer" /v "MultipleInvokePromptMinimum" /t REG_DWORD /d 100 /f
}

# Function to hide recent items in Quick Access
function Hide-RecentItems {
    reg add "HKCU\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer" /v "ShowFrequent" /t REG_DWORD /d 0 /f
    reg add "HKCU\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer" /v "ShowRecent" /t REG_DWORD /d 0 /f
    reg add "HKCU\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\Advanced" /v "Start_TrackDocs" /t REG_DWORD /d 0 /f
    reg add "HKCU\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\Explorer" /v "ClearRecentDocsOnExit" /t REG_DWORD /d 1 /f
    reg add "HKCU\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\Explorer" /v "NoRecentDocsHistory" /t REG_DWORD /d 1 /f
    reg add "HKCU\SOFTWARE\Policies\Microsoft\Windows\Explorer" /v "NoRemoteDestinations" /t REG_DWORD /d 1 /f
}

# Function to minimize mouse hover time for item info
function Set-MouseHoverTimeForItemInfo {
    reg add "HKCU\Control Panel\Mouse" /v "MouseHoverTime" /t REG_SZ /d "20" /f
}

# Function to configure File Explorer to open to This PC
function Set-FileExplorerToThisPC {
    reg add "HKCU\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\Advanced" /v "LaunchTo" /t REG_DWORD /d 1 /f
}

# Function to remove previous versions from Explorer
function Remove-PreviousVersionsFromExplorer {
    reg delete 'HKCU\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer' /v 'NoPreviousVersionsPage' /f
    reg delete 'HKCU\SOFTWARE\Policies\Microsoft\PreviousVersions' /v 'DisableLocalPage' /f
}

# Function to remove shortcut text
function Remove-ShortcutText {
    reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\Explorer\NamingTemplates" /v "ShortcutNameTemplate" /t REG_SZ /d ""%s.lnk"" /f
}

# Function to configure Explorer to show all files with file extensions
function Show-AllFilesWithExtensions {
    reg add "HKCU\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\Advanced" /v "Hidden" /t REG_DWORD /d 1 /f
    reg add "HKCU\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\Advanced" /v "HideFileExt" /t REG_DWORD /d 0 /f
}

# Function to use compact mode in File Explorer
function Enable-CompactMode {
    reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" /v "UseCompactMode" /t REG_DWORD /d 1 /f
}

# Function to not show Edge tabs in Alt-Tab
function Disable-ShowEdgeTabsInAltTab {
    reg add "HKCU\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\Advanced" /v "MultiTaskingAltTabFilter" /t REG_DWORD /d 3 /f
}

# Function to disable AutoRun
function Disable-AutoRun {
    reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\Explorer\AutoplayHandlers" /v "DisableAutoplay" /t REG_DWORD /d 1 /f
    reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\Explorer\AutoplayHandlers\EventHandlersDefaultSelection\CameraAlternate" /v "MSTakeNoAction" /t REG_NONE /d "" /f
    reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\Explorer\AutoplayHandlers\EventHandlersDefaultSelection\StorageOnArrival" /v "MSTakeNoAction" /t REG_NONE /d "" /f
    reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\Explorer\AutoplayHandlers\UserChosenExecuteHandlers\CameraAlternate\ShowPicturesOnArrival" /v "MSTakeNoAction" /t REG_NONE /d "" /f
    reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\Explorer\AutoplayHandlers\UserChosenExecuteHandlers\StorageOnArrival" /v "MSTakeNoAction" /t REG_NONE /d "" /f
}

# Function to disable Aero Shake
function Disable-AeroShake {
    reg add "HKCU\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\Advanced" /v "DisallowShaking" /t REG_DWORD /d 1 /f
}

# Function to disable low disk space checks
function Disable-LowDiskSpaceChecks {
    reg add "HKCU\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\Explorer" /v "NoLowDiskSpaceChecks" /t REG_DWORD /d 1 /f
}

# Function to disable menu hover delay
function Disable-MenuHoverDelay {
    reg add "HKCU\Control Panel\Desktop" /v "MenuShowDelay" /t REG_SZ /d "0" /f
}

# Function to disable shared experiences
function Disable-SharedExperiences {
    reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\CDP\SettingsPage" /v "BluetoothLastDisabledNearShare" /t REG_DWORD /d 0 /f
    reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\CDP" /v "NearShareChannelUserAuthzPolicy" /t REG_DWORD /d 0 /f
    reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\CDP" /v "CdpSessionUserAuthzPolicy" /t REG_DWORD /d 1 /f
}

# Function to disable recommendations in the Start Menu
function Disable-StartMenuRecommendations {
    reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" /v "Start_IrisRecommendations" /t REG_DWORD /d 0 /f
    reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" /v "Start_AccountNotifications" /t REG_DWORD /d 0 /f
}

# Function to restore old context menu in Windows 11
function Restore-OldContextMenu {
    & "$windir\AtlasDesktop\4. Interface Tweaks\Context Menus\Windows 11\Old Context Menu (default).cmd" /justcontext
}

# Function to set unpinned control center items
function Set-UnpinnedControlCenterItems {
    Stop-Process -Name explorer -Force

    if ((Get-WmiObject -Class Win32_OperatingSystem).Version -like "10.0.19045"){
        # Windows 10
        reg add "HKCU\Control Panel\Quick Actions\Control Center\Unpinned" /v "Microsoft.QuickAction.Connect" /t REG_NONE /d "" /f
        reg add "HKCU\Control Panel\Quick Actions\Control Center\Unpinned" /v "Microsoft.QuickAction.Location" /t REG_NONE /d "" /f
        reg add "HKCU\Control Panel\Quick Actions\Control Center\Unpinned" /v "Microsoft.QuickAction.ScreenClipping" /t REG_NONE /d "" /f
        reg add "HKCU\Control Panel\Quick Actions\Control Center\QuickActionsStateCapture" /v "Toggles" /t REG_SZ /d "Toggles,Microsoft.QuickAction.BlueLightReduction:false,Microsoft.QuickAction.AllSettings:false,Microsoft.QuickAction.Project:false" /f
    }
    else{
        # Windows 11
        reg add "HKCU\Control Panel\Quick Actions\Control Center\Unpinned" /v "Microsoft.QuickAction.Cast" /t REG_NONE /d "" /f
        reg add "HKCU\Control Panel\Quick Actions\Control Center\Unpinned" /v "Microsoft.QuickAction.NearShare" /t REG_NONE /d "" /f
        reg add "HKCU\Control Panel\Quick Actions\Control Center\QuickActionsStateCapture" /v "Toggles" /t REG_SZ /d "Toggles,Microsoft.QuickAction.BlueLightReduction:false,Microsoft.QuickAction.Accessibility:false,Microsoft.QuickAction.ProjectL2:false" /f
    }


    Start-Process -FilePath explorer.exe
}

# Function to show more pins in the Start Menu
function Show-MorePinsInStartMenu {
    reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" /v "Start_Layout" /t REG_DWORD /d 1 /f
}

# Function to decrease shutdown time
function Set-ShutdownTime {
    reg add "HKCU\Control Panel\Desktop" /v "HungAppTimeout" /t REG_SZ /d "2000" /f
    reg add "HKCU\Control Panel\Desktop" /v "WaitToKillAppTimeOut" /t REG_SZ /d "2000" /f
    reg add "HKLM\SYSTEM\CurrentControlSet\Control" /v "WaitToKillServiceTimeout" /t REG_SZ /d "2000" /f
}

# Function to disable startup delay
function Disable-StartupDelay {
    reg add "HKCU\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\Serialize" /v "StartupDelayInMSec" /t REG_DWORD /d 0 /f
}

# Function to force close applications on session end
function Set-CloseApplicationsOnSessionEnd {
    reg add "HKCU\Control Panel\Desktop" /v "AutoEndTasks" /t REG_SZ /d "1" /f
}

# Function to show Command Prompt on Win+X
function Show-CommandPromptOnWinX {
    reg add "HKCU\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\Advanced" /v "DontUsePowerShellOnWinX" /t REG_DWORD /d 1 /f
}

# Function to disable Microsoft Copilot
function Disable-MicrosoftCopilot {
    reg add "HKCU\Software\Policies\Microsoft\Windows\WindowsCopilot" /v "TurnOffWindowsCopilot" /t REG_DWORD /d 1 /f
}

# Function to disable Show Desktop peek on taskbar
function Disable-ShowDesktopPeek {
    reg add "HKCU\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\Advanced" /v "DisablePreviewDesktop" /t REG_DWORD /d 1 /f
}

# Function to never use tablet mode
function Hide-TabletMode {
    reg add "HKCU\SOFTWARE\Microsoft\Windows\CurrentVersion\ImmersiveShell" /v "SignInMode" /t REG_DWORD /d 1 /f
}

# Function to disable Windows Chat
function Disable-WindowsChat {
    reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows\Windows Chat" /v "ChatIcon" /t REG_DWORD /d 3 /f
    reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" /v "TaskbarMn" /t REG_DWORD /d 0 /f
}

# Function to add 'End task' to the taskbar
function Add-EndTaskToTaskbar {
    reg add "HKCU\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\Advanced\TaskbarDeveloperSettings" /v "TaskbarEndTask" /t REG_DWORD /d 1 /f
}

# Function to disable Task View on taskbar
function Disable-TaskViewOnTaskbar {
    reg delete 'HKCU\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\MultiTaskingView\AllUpView' /v 'Enabled' /f
    reg add "HKCU\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\Advanced" /v "ShowTaskViewButton" /t REG_DWORD /d 0 /f
}

# Function to set taskbar alignment to left
function Set-TaskbarAlignLeft {
    reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" /v "TaskbarAl" /t REG_DWORD /d 0 /f
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
    & bcdedit /timeout 10
    & bcdedit /set bootmenupolicy legacy
}

# Function to disable wallpaper compression
function Disable-WallpaperCompression {
    reg add "HKCU\Control Panel\Desktop" /v "JPEGImportQuality" /t REG_DWORD /d 100 /f
}
# Function to configure Start Menu
function Set-StartMenu {
    reg add "HKLM\SOFTWARE\Microsoft\PolicyManager\current\device\Start" /v "ConfigureStartPins" /t REG_SZ /d '{"pinnedList":[{"packagedAppId":"windows.immersivecontrolpanel_cw5n1h2txyewy!microsoft.windows.immersivecontrolpanel"},{"packagedAppId":"Microsoft.WindowsTerminal_8wekyb3d8bbwe!App"},{"desktopAppLink":"%APPDATA%\\Microsoft\\Windows\\Start Menu\\Programs\\File Explorer.lnk"},{"packagedAppId":"Microsoft.WindowsStore_8wekyb3d8bbwe!App"},{"packagedAppId":"Microsoft.GamingApp_8wekyb3d8bbwe!Microsoft.Xbox.App"},{"packagedAppId":"Microsoft.WindowsCalculator_8wekyb3d8bbwe!App"},{"packagedAppId":"Microsoft.WindowsNotepad_8wekyb3d8bbwe!App"},{"packagedAppId":"Microsoft.Paint_8wekyb3d8bbwe!App"},{"packagedAppId":"Microsoft.SecHealthUI_8wekyb3d8bbwe!SecHealthUI"}]}' /f

    foreach ($userKey in (Get-RegUserPaths).PsPath) {
        $default = if ($userKey -match 'AME_UserHive_Default') { $true }
        $sid = Split-Path $userKey -Leaf

        # Get Local AppData
        $appData = if ($default) {
            Get-UserPath -Folder 'F1B32785-6FBA-4FCF-9D55-7B8E7F157091'
        } else {
            (Get-ItemProperty "$userKey\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\Shell Folders" -Name 'Local AppData' -EA 0).'Local AppData'
        }

        Write-Title "Configuring Start Menu for '$sid'..."
        if ([string]::IsNullOrEmpty($appData) -or !(Test-Path $appData)) {
            Write-Error "Couldn't find AppData value for $sid!"
        } else {
            Write-Output "Copying default layout XML"
            Copy-Item -Path "$windir\AtlasModules\Other\Layout.xml" -Destination "$appdata\Microsoft\Windows\Shell\LayoutModification.xml" -Force

            if (!$default) {
                Write-Output "Clearing Start Menu pinned items"

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
            $tilegrid = Get-ChildItem -Path "$userKey\SOFTWARE\Microsoft\Windows\CurrentVersion\CloudStore\Store\Cache\DefaultAccount" -Recurse | Where-Object { $_.Name -match "start.tilegrid" }
            foreach ($key in $tilegrid) {
                Remove-Item -Path $key.PSPath -Force
            }
        }

        Write-Output "Removing advertisements/stubs from Start Menu (23H2+)"
        Remove-ItemProperty -Path "$userKey\SOFTWARE\Microsoft\Windows\CurrentVersion\Start" -Name 'Config' -Force -EA 0
    }
    Remove-AppxPackage -Package 'Microsoft.Windows.StartMenuExperienceHost*'

    reg add "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\Explorer" /v "NoStartMenuMFUprogramsList" /t REG_DWORD /d 1 /f
    reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows\Explorer" /v "ShowOrHideMostUsedApps" /t REG_DWORD /d 2 /f
    reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows\Explorer" /v "HideRecentlyAddedApps" /t REG_DWORD /d 1 /f
    reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows\Explorer" /v "HideRecommendedPersonalizedSites" /t REG_DWORD /d 1 /f
}

# Function to configure Windows Ink Workspace
function Set-WindowsInkWorkspace {
    reg add "HKCU\SOFTWARE\Microsoft\Windows\CurrentVersion\PenWorkspace" /v "PenWorkspaceAppSuggestionsEnabled" /t REG_DWORD /d 0 /f
}

# Function to disable automatic Store app archiving
function Disable-AutomaticStoreAppArchiving {
    & "$windir\AtlasDesktop\3. General Configuration\Store App Archiving\Disable Store App Archiving (default).cmd" /justcontext
}

# Function to disable dynamic lighting
function Disable-DynamicLighting {
    reg add "HKCU\Software\Microsoft\Lighting" /v "AmbientLightingEnabled" /t REG_DWORD /d 0 /f
}

# Function to disable mouse acceleration
function Disable-MouseAcceleration {
    reg add "HKCU\Control Panel\Mouse" /v "MouseSpeed" /t REG_SZ /d 0 /f
    reg add "HKCU\Control Panel\Mouse" /v "MouseThreshold1" /t REG_SZ /d 0 /f
    reg add "HKCU\Control Panel\Mouse" /v "MouseThreshold2" /t REG_SZ /d 0 /f
}

# Function to disable screen capture hotkey
function Disable-ScreenCaptureHotkey {
    reg add "HKCU\Control Panel\Keyboard" /v "PrintScreenKeyForSnippingEnabled" /t REG_DWORD /d 0 /f
}

# Function to disable spell checking
function Disable-SpellChecking {
    reg add "HKCU\SOFTWARE\Microsoft\TabletTip\1.7" /v "EnableAutocorrection" /t REG_DWORD /d 0 /f
    reg add "HKCU\SOFTWARE\Microsoft\TabletTip\1.7" /v "EnableDoubleTapSpace" /t REG_DWORD /d 0 /f
    reg add "HKCU\SOFTWARE\Microsoft\TabletTip\1.7" /v "EnablePredictionSpaceInsertion" /t REG_DWORD /d 0 /f
    reg add "HKCU\SOFTWARE\Microsoft\TabletTip\1.7" /v "EnableSpellchecking" /t REG_DWORD /d 0 /f
    reg add "HKCU\SOFTWARE\Microsoft\TabletTip\1.7" /v "EnableTextPrediction" /t REG_DWORD /d 0 /f
}

# Function to disable unnecessary touch keyboard settings
function Disable-UnnecessaryTouchKeyboardSettings {
    reg add "HKCU\SOFTWARE\Microsoft\TabletTip\1.7" /v "EnableAutoShiftEngage" /t REG_DWORD /d 0 /f
    reg add "HKCU\SOFTWARE\Microsoft\TabletTip\1.7" /v "EnableKeyAudioFeedback" /t REG_DWORD /d 0 /f
}

# Function to disable touch visual feedback
function Disable-TouchVisualFeedback {
    reg add "HKCU\Control Panel\Cursors" /v "GestureVisualization" /t REG_DWORD /d 0 /f
    reg add "HKCU\Control Panel\Cursors" /v "ContactVisualization" /t REG_DWORD /d 0 /f
}

# Function to disable Windows Feedback
function Disable-WindowsFeedback {
    reg add "HKCU\SOFTWARE\Microsoft\Siuf\Rules" /v "NumberOfSIUFInPeriod" /t REG_DWORD /d 0 /f
    reg delete 'HKCU\SOFTWARE\Microsoft\Siuf\Rules' /v 'PeriodInNanoSeconds' /f
    reg add "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\DataCollection" /v "DoNotShowFeedbackNotifications" /t REG_DWORD /d 1 /f
}

# Function to disable Windows Spotlight
function Disable-WindowsSpotlight {
    reg add "HKCU\SOFTWARE\Policies\Microsoft\Windows\CloudContent" /v "DisableWindowsSpotlightFeatures" /t REG_DWORD /d 1 /f
    reg add "HKCU\SOFTWARE\Policies\Microsoft\Windows\CloudContent" /v "DisableWindowsSpotlightWindowsWelcomeExperience" /t REG_DWORD /d 1 /f
    reg add "HKCU\SOFTWARE\Policies\Microsoft\Windows\CloudContent" /v "DisableWindowsSpotlightOnActionCenter" /t REG_DWORD /d 1 /f
    reg add "HKCU\SOFTWARE\Policies\Microsoft\Windows\CloudContent" /v "DisableWindowsSpotlightOnSettings" /t REG_DWORD /d 1 /f
    reg add "HKCU\SOFTWARE\Policies\Microsoft\Windows\CloudContent" /v "DisableThirdPartySuggestions" /t REG_DWORD /d 1 /f
    reg add "HKCU\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\HideDesktopIcons\NewStartPanelt" /v "{2cc5ca98-6485-489a-920e-b3e88a6ccce3}" /t REG_DWORD /d 1 /f
}

# Function to not reduce sounds while in a call
function Disable-ReduceSoundsWhileInCall {
    reg add "HKCU\SOFTWARE\Microsoft\Multimedia\Audio" /v "UserDuckingPreference" /t REG_DWORD /d 3 /f
}

# Function to hide disabled and disconnected devices in sounds panel
function Hide-DisabledAndDisconnectedDevicesInSoundsPanel {
    reg add "HKCU\SOFTWARE\Microsoft\Multimedia\Audio\DeviceCpl" /v "ShowDisconnectedDevices" /t REG_DWORD /d 0 /f
    reg add "HKCU\SOFTWARE\Microsoft\Multimedia\Audio\DeviceCpl" /v "ShowHiddenDevices" /t REG_DWORD /d 0 /f
}

# Function to configure visual effects
function Set-VisualEffects {
    reg add "HKCU\Control Panel\Desktop" /v "FontSmoothing" /t REG_SZ /d "2" /f
    reg add "HKCU\Control Panel\Desktop" /v "UserPreferencesMask" /t REG_BINARY /d "9012038010000000" /f
    reg add "HKCU\Control Panel\Desktop" /v "DragFullWindows" /t REG_SZ /d "1" /f
    reg add "HKCU\Control Panel\Desktop\WindowMetrics" /v "MinAnimate" /t REG_SZ /d "0" /f
    reg add "HKCU\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\Advanced" /v "ListviewAlphaSelect" /t REG_DWORD /d 1 /f
    reg add "HKCU\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\Advanced" /v "IconsOnly" /t REG_DWORD /d 0 /f
    reg add "HKCU\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\Advanced" /v "TaskbarAnimations" /t REG_DWORD /d 0 /f
    reg add "HKCU\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\Advanced" /v "ListviewShadow" /t REG_DWORD /d 1 /f
    reg add "HKCU\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\VisualEffects" /v "VisualFXSetting" /t REG_DWORD /d 3 /f
    reg add "HKCU\SOFTWARE\Microsoft\Windows\DWM" /v "EnableAeroPeek" /t REG_DWORD /d 0 /f
    reg add "HKCU\SOFTWARE\Microsoft\Windows\DWM" /v "AlwaysHibernateThumbnails" /t REG_DWORD /d 0 /f
}

function Invoke-AllQolOptimizations {
    Write-Host "Running QOL optimizations"
    Set-AtlasTheme
    Set-TooltipColorBlue
    Disable-ThemeChangesToPersonalizedFeatures
    Disable-ReadAndScan
    Disable-AnnoyingFeaturesAndShortcuts
    Disable-AccessibilityToolShortcut
    Disable-EaseOfAccessSounds
    Remove-ExtractFromContextMenu
    Remove-PrintingFromContextMenus
    Show-MoreDetailsOnTransfers
    Set-SendToContextMenu
    Disable-UseCheckBoxesToSelectItems
    Hide-GalleryInFileExplorer
    Disable-SearchingForInvalidShortcuts
    Disable-NetworkNavigationPaneInExplorer
    Hide-OfficeFilesInQuickAccess
    Show-FullContextMenuOnItems
    Hide-RecentItems
    Set-MouseHoverTimeForItemInfo
    Set-FileExplorerToThisPC
    Remove-PreviousVersionsFromExplorer
    Remove-ShortcutText
    Show-AllFilesWithExtensions
    Enable-CompactMode
    Disable-ShowEdgeTabsInAltTab
    Disable-AutoRun
    Disable-AeroShake
    Disable-LowDiskSpaceChecks
    Disable-MenuHoverDelay
    Disable-SharedExperiences
    Disable-StartMenuRecommendations
    Restore-OldContextMenu
    Set-UnpinnedControlCenterItems
    Show-MorePinsInStartMenu
    Set-ShutdownTime
    Disable-StartupDelay
    Set-CloseApplicationsOnSessionEnd
    Show-CommandPromptOnWinX
    Disable-MicrosoftCopilot
    Disable-ShowDesktopPeek
    Hide-TabletMode
    Disable-WindowsChat
    Add-EndTaskToTaskbar
    Disable-TaskViewOnTaskbar
    Set-TaskbarAlignLeft
    Add-NetworkSharingShortcut
    Set-BootConfiguration
    Disable-WallpaperCompression
    Set-StartMenu
    Set-WindowsInkWorkspace
    Disable-AutomaticStoreAppArchiving
    Disable-DynamicLighting
    Disable-MouseAcceleration
    Disable-ScreenCaptureHotkey
    Disable-SpellChecking
    Disable-UnnecessaryTouchKeyboardSettings
    Disable-TouchVisualFeedback
    Disable-WindowsFeedback
    Disable-WindowsSpotlight
    Disable-ReduceSoundsWhileInCall
    Hide-DisabledAndDisconnectedDevicesInSoundsPanel
    Set-VisualEffects
}

# Export functions for module
Export-ModuleMember -Function Invoke-AllQolOptimizations
