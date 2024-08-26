$windir = [Environment]::GetFolderPath('Windows')
$atlasDesktop = "$windir\AtlasDesktop"
$atlasModules = "$windir\AtlasModules"

$title = 'Preparing Atlas user settings...'

if (!(Test-Path $atlasDesktop) -or !(Test-Path $atlasModules)) {
    Write-Host "Atlas was about to configure user settings, but its files weren't found. :(" -ForegroundColor Red
    $null = Read-Host "Press Enter to exit"
    exit 1
}

$Host.UI.RawUI.WindowTitle = $title
Write-Host $title -ForegroundColor Yellow
Write-Host $('-' * ($title.length + 3)) -ForegroundColor Yellow
Write-Host "You'll be logged out in 10 to 20 seconds, and once you login again, your new account will be ready for use."

# Disable Windows 11 context menu & 'Gallery' in File Explorer
if ([System.Environment]::OSVersion.Version.Build -ge 22000) {
    reg import "$atlasDesktop\4. Interface Tweaks\Context Menus\Windows 11\Old Context Menu (default).reg" *>$null
    reg import "$atlasDesktop\4. Interface Tweaks\File Explorer Customization\Gallery\Disable Gallery (default).reg" *>$null

    # Set ThemeMRU (recent themes)
    ThemeMRU | Out-Null
}

# Set lockscreen wallpaper
& "$atlasModules\Scripts\lockscreen.ps1"

# Disable 'Network' in navigation pane
reg import "$atlasDesktop\3. General Configuration\File Sharing\Network Navigation Pane\Disable Network Navigation Pane (default).reg" *>$null

# Set visual effects
& "$atlasDesktop\4. Interface Tweaks\Visual Effects\Atlas Visual Effects (default).cmd" /silent

# Pin 'Videos' and 'Music' folders to Home/Quick Acesss
$o = new-object -com shell.application
$currentPins = $o.Namespace('shell:::{679f85cb-0220-4080-b29b-5540cc05aab6}').Items() | ForEach-Object { $_.Path }
foreach ($path in @(
    [Environment]::GetFolderPath('MyVideos'),
    [Environment]::GetFolderPath('MyMusic')
)) {
    if ($currentPins -notcontains $path) {
        $o.Namespace($path).Self.InvokeVerb('pintohome')
    }
}

# Set taskbar search box to an icon
Set-ItemProperty -Path "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Search" -Name "SearchboxTaskbarMode" -Value 1

# Leave
Start-Sleep 5
logoff