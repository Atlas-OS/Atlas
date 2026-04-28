# Guard against re-running after a profile reset. Windows 24H2/25H2 can recreate a user profile
# from the Default template after sleep/wake, which causes RunOnce to fire this script again.
# We track per-SID completion in HKLM (survives profile resets, unlike HKCU) and exit early if
# this user was already set up. -ErrorAction Stop ensures real errors are not silently swallowed.
$sid = [System.Security.Principal.WindowsIdentity]::GetCurrent().User.Value
try {
    if ((Get-ItemProperty 'HKLM:\SOFTWARE\AtlasOS\UserSetup' -Name $sid -ErrorAction Stop).$sid -eq 1) { exit }
} catch {
    # Key or property does not exist yet - this is the first run, continue normally
}

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
$null = New-Item -Path 'HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Search' -Force -ErrorAction SilentlyContinue
Set-ItemProperty -Path 'HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Search' -Name 'SearchboxTaskbarMode' -Value 1 -Type DWord -Force

# Write the per-SID completion marker so the guard at the top of this script triggers on any
# future re-run. The key is created if it does not exist yet. If writing fails for any reason
# (e.g. permissions), a warning is shown so the failure is visible rather than silent.
try {
    if (-not (Test-Path 'HKLM:\SOFTWARE\AtlasOS\UserSetup')) {
        New-Item 'HKLM:\SOFTWARE\AtlasOS\UserSetup' -Force | Out-Null
    }
    Set-ItemProperty 'HKLM:\SOFTWARE\AtlasOS\UserSetup' -Name $sid -Value 1 -Type DWord -Force
} catch {
    Write-Warning "Failed to write setup marker for SID '$sid': $($_.Exception.Message)"
}

# Leave
Start-Sleep 5
logoff
