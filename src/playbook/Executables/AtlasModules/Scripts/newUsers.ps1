# On Windows 24H2/25H2, a sleep/wake cycle can cause Windows to recreate an existing user profile
# from the Default template. This re-triggers the RunOnce entry and runs this script a second time,
# which forces a logoff and wipes the user's settings.
#
# To prevent this, prefer a completion marker in HKLM after setup finishes (see bottom of script).
# HKLM survives profile resets; HKCU lives inside the profile folder and would be wiped along with it.
# Standard users cannot create HKLM keys, so HKCU is used as a compatibility fallback.
#
# The marker key is the user's SID (Security Identifier) — a unique, permanent ID assigned to each
# Windows account. Unlike a username, the SID never changes even if the profile is deleted and
# recreated. Using it as the key name lets us track setup state per user on shared machines.
param([switch]$FinalizeSearch)

$sid = [System.Security.Principal.WindowsIdentity]::GetCurrent().User.Value
$machineMarkerPath = 'HKLM:\SOFTWARE\AtlasOS\UserSetup'
$userMarkerPath = 'HKCU:\SOFTWARE\AtlasOS\UserSetup'

function Get-SetupMarker {
    foreach ($path in @($machineMarkerPath, $userMarkerPath)) {
        try {
            $value = Get-ItemPropertyValue -Path $path -Name $sid -ErrorAction Stop
            return [int]$value
        }
        catch {
            continue
        }
    }

    return 0
}

function Test-SetupMarker {
    return (Get-SetupMarker) -ge 2
}

function Set-SetupMarker {
    param([ValidateSet(1, 2)][int]$Value = 2)

    $errors = @()

    foreach ($path in @($machineMarkerPath, $userMarkerPath)) {
        try {
            $null = New-Item -Path $path -Force -ErrorAction Stop
            Set-ItemProperty -Path $path -Name $sid -Value $Value -Type DWord -Force -ErrorAction Stop
            return
        }
        catch {
            $errors += "'$path': $($_.Exception.Message)"
        }
    }

    Write-Warning "Failed to write setup marker for SID '$sid'. $($errors -join '; ')"
}

function Set-NewUsersRunOnce {
    $runOncePath = 'HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\RunOnce'
    $command = 'powershell -EP RemoteSigned -NoP & """$([Environment]::GetFolderPath(''Windows''))\AtlasModules\Scripts\newUsers.ps1"""'

    $null = New-Item -Path $runOncePath -Force -ErrorAction Stop
    Set-ItemProperty -Path $runOncePath -Name 'RunScript' -Value $command -Type String -Force -ErrorAction Stop
}

function Set-SearchTaskbarMode {
    $searchPath = 'HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Search'
    $searchSettingsPath = 'HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\SearchSettings'
    $explorerPolicyPath = 'HKCU:\SOFTWARE\Policies\Microsoft\Windows\Explorer'

    $null = New-Item -Path $searchPath -Force -ErrorAction Stop
    $null = New-Item -Path $searchSettingsPath -Force -ErrorAction Stop

    Set-ItemProperty -Path $searchPath -Name 'BingSearchEnabled' -Value 0 -Type DWord -Force -ErrorAction Stop
    Set-ItemProperty -Path $searchPath -Name 'SearchboxTaskbarMode' -Value 1 -Type DWord -Force -ErrorAction Stop
    Set-ItemProperty -Path $searchPath -Name 'SearchboxTaskbarModeCache' -Value 1 -Type DWord -Force -ErrorAction Stop
    Set-ItemProperty -Path $searchSettingsPath -Name 'IsAADCloudSearchEnabled' -Value 0 -Type DWord -Force -ErrorAction Stop
    Set-ItemProperty -Path $searchSettingsPath -Name 'IsDeviceSearchHistoryEnabled' -Value 0 -Type DWord -Force -ErrorAction Stop
    Set-ItemProperty -Path $searchSettingsPath -Name 'IsDynamicSearchBoxEnabled' -Value 0 -Type DWord -Force -ErrorAction Stop
    Set-ItemProperty -Path $searchSettingsPath -Name 'IsMSACloudSearchEnabled' -Value 0 -Type DWord -Force -ErrorAction Stop
    Set-ItemProperty -Path $searchSettingsPath -Name 'SafeSearchMode' -Value 0 -Type DWord -Force -ErrorAction Stop
    try {
        $null = New-Item -Path $explorerPolicyPath -Force -ErrorAction Stop
        Set-ItemProperty -Path $explorerPolicyPath -Name 'DisableSearchBoxSuggestions' -Value 1 -Type DWord -Force -ErrorAction Stop
    }
    catch {
        Write-Warning "Couldn't write optional search policy '$explorerPolicyPath': $($_.Exception.Message)"
    }
}

function Start-DelayedSearchFinalizer {
    $scriptPath = Join-Path -Path ([Environment]::GetFolderPath('Windows')) -ChildPath 'AtlasModules\Scripts\newUsers.ps1'
    $arguments = @(
        '-NoProfile'
        '-ExecutionPolicy'
        'RemoteSigned'
        '-WindowStyle'
        'Hidden'
        '-File'
        "`"$scriptPath`""
        '-FinalizeSearch'
    )

    Start-Process -FilePath 'powershell.exe' -ArgumentList $arguments -WindowStyle Hidden -ErrorAction Stop
}

function Set-AtlasTaskbarPins {
    param([AllowNull()][string]$Browser)

    $taskbarPinsScript = Join-Path -Path $atlasModules -ChildPath 'Scripts\Internal\TaskbarPins.ps1'
    if (!(Test-Path -LiteralPath $taskbarPinsScript -PathType Leaf)) {
        throw "Taskbar pins script '$taskbarPinsScript' was not found."
    }

    if ([string]::IsNullOrWhiteSpace($Browser)) {
        & $taskbarPinsScript -CurrentUserOnly -NoExplorerStop
    }
    else {
        & $taskbarPinsScript -Browser $Browser -CurrentUserOnly -NoExplorerStop
    }
}

if ($FinalizeSearch) {
    Start-Sleep -Seconds 20
    Set-SearchTaskbarMode
    Stop-Process -Name explorer -Force -ErrorAction SilentlyContinue
    Start-Sleep -Seconds 2
    Start-Process -FilePath explorer.exe -ErrorAction SilentlyContinue
    Start-Sleep -Seconds 5
    Set-SearchTaskbarMode
    exit
}

$setupMarker = Get-SetupMarker
if ($setupMarker -ge 2) {
    exit
}

$windir = [Environment]::GetFolderPath('Windows')
& "$windir\AtlasModules\initPowerShell.ps1"
$atlasDesktop = "$windir\AtlasDesktop"
$atlasModules = "$windir\AtlasModules"

if (!(Test-Path $atlasDesktop) -or !(Test-Path $atlasModules)) {
    Write-Host "Atlas was about to configure user settings, but its files weren't found. :(" -ForegroundColor Red
    Read-Pause
    exit 1
}

if ($setupMarker -lt 1) {
    $title = 'Preparing Atlas user settings...'
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

Set-AtlasTaskbarPins -Browser $browser
Set-SearchTaskbarMode

if ($setupMarker -lt 1) {
    Set-SetupMarker -Value 1
    Set-NewUsersRunOnce
    Start-Sleep 5
    logoff
    exit
}

# Write the completion marker for this user so the guard above exits early on any future re-run.
Stop-Process -Name explorer -Force -ErrorAction SilentlyContinue
Set-SearchTaskbarMode
Set-SetupMarker -Value 2

Start-Process -FilePath explorer.exe -ErrorAction SilentlyContinue
Start-DelayedSearchFinalizer
