# QOL domain functions: Explorer

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
