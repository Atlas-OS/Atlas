$windir = [Environment]::GetFolderPath('Windows')
& "$windir\AtlasModules\initPowerShell.ps1"
$atlasDesktop = "$windir\AtlasDesktop"
$atlasModules = "$windir\AtlasModules"

$title = 'Preparing Atlas user settings...'

if (!(Test-Path $atlasDesktop) -or !(Test-Path $atlasModules)) {
    Write-Host "Atlas was about to configure user settings, but its files weren't found. :(" -ForegroundColor Red
    Read-Pause
    exit 1
}

$Host.UI.RawUI.WindowTitle = $title
Write-Host $title -ForegroundColor Yellow
Write-Host $('-' * ($title.length + 3)) -ForegroundColor Yellow
Write-Host "You'll be logged out in 10 to 20 seconds, and once you login again, your new account will be ready for use."

$env:ATLAS_USER_CONTEXT = "1"
try {
    # Disable Windows 11 context menu & 'Gallery' in File Explorer
    if ([System.Environment]::OSVersion.Version.Build -ge 22000) {
        & "$atlasDesktop\4. Interface Tweaks\Context Menus\Windows 11\Old Context Menu (default).cmd" /silent
        & "$atlasDesktop\4. Interface Tweaks\File Explorer Customization\Gallery\Disable Gallery (default).cmd" /silent

        # Set ThemeMRU (recent themes)
        Set-Theme -Path "$([Environment]::GetFolderPath('Windows'))\Resources\Themes\atlas-v0.5.x-dark.theme"
        Set-ThemeMRU | Out-Null
    }

    # Set lockscreen wallpaper
    try {
        Set-LockscreenImage
    }
    catch {
        Write-Warning "Failed to set lockscreen image: $($_.Exception.Message)"
    }

    # Disable 'Network' in navigation pane
    & "$atlasDesktop\3. General Configuration\File Sharing\Network Navigation Pane\Disable Network Navigation Pane (default).cmd" /silent

    # Disable Automatic Folder Discovery
    & "$atlasDesktop\4. Interface Tweaks\File Explorer Customization\Automatic Folder Discovery\Disable Automatic Folder Discovery (default).cmd" /silent

    # Set visual effects
    & "$atlasDesktop\4. Interface Tweaks\Visual Effects (Animations)\Atlas Visual Effects (default).cmd" /silent
}
finally {
    Remove-Item "Env:\ATLAS_USER_CONTEXT" -ErrorAction SilentlyContinue
}

# Set taskbar pins
$browser = $null
$setupOptionsPath = "HKLM:\SOFTWARE\AtlasOS\SetupOptions"
$allowedBrowsers = @("Brave", "Firefox", "LibreWolf", "Google Chrome", "Microsoft Edge")

try {
    $browser = Get-ItemPropertyValue -Path $setupOptionsPath -Name "Browser" -ErrorAction Stop
}
catch {
    Write-Warning "Couldn't read browser selection from '$setupOptionsPath'. Falling back to default taskbar pins."
}

if (![string]::IsNullOrWhiteSpace($browser) -and $browser -notin $allowedBrowsers) {
    Write-Warning "Invalid browser value '$browser' found in '$setupOptionsPath'. Falling back to default taskbar pins."
    $browser = $null
}

if ([string]::IsNullOrWhiteSpace($browser)) {
    $browser = $null
}

& "$atlasModules\Scripts\taskbarPins.ps1" $browser
& reg.exe add "HKCU\SOFTWARE\Microsoft\Windows\CurrentVersion\Search" /v "SearchboxTaskbarMode" /t REG_DWORD /d 1 /f *> $null

# Leave
Start-Sleep 5 
logoff
