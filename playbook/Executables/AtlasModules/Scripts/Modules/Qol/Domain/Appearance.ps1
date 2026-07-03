# QOL domain functions: Appearance

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

function Disable-WallpaperCompression {
    # JPEGImportQuality 100 stops Windows from re-compressing wallpapers when applying them
    Set-ItemProperty -Path 'HKCU:\Control Panel\Desktop' -Name 'JPEGImportQuality' -Value 100 -Type DWord -Force
}

# Function to configure Start Menu

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
    $null = New-Item -Path 'HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\HideDesktopIcons\NewStartPanel' -Force -ErrorAction SilentlyContinue
    Set-ItemProperty -Path 'HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\HideDesktopIcons\NewStartPanel' -Name '{2cc5ca98-6485-489a-920e-b3e88a6ccce3}' -Value 1 -Type DWord -Force
}

# Function to not reduce sounds while in a call

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

        if (!$default -and ([string]::IsNullOrEmpty($appData) -or !(Test-Path $appData -PathType Container))) {
            $profilePath = (Get-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\ProfileList\$sid" -Name ProfileImagePath -ErrorAction SilentlyContinue).ProfileImagePath
            if (![string]::IsNullOrEmpty($profilePath)) {
                $appData = Join-Path ([Environment]::ExpandEnvironmentVariables($profilePath)) 'AppData\Local'
            }
        }

        Write-Title "Configuring Start Menu for '$sid'..."
        if ([string]::IsNullOrEmpty($appData) -or !(Test-Path $appData -PathType Container)) {
            Write-Warning "Couldn't find Local AppData path for $sid; skipping Start Menu file cleanup."
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
