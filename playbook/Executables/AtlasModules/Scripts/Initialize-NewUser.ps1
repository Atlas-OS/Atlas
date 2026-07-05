# On Windows 24H2/25H2, a sleep/wake cycle can cause Windows to recreate an existing user profile
# from the Default template. This re-triggers the RunOnce entry and runs this script a second time,
# which forces a logoff and wipes the user's settings.
#
# To prevent this, prefer a completion marker in HKLM after setup finishes (see bottom of script).
# HKLM survives profile resets; HKCU lives inside the profile folder and would be wiped along with it.
# Standard users cannot create HKLM keys, so HKCU is used as a compatibility fallback.
#
# The marker key is the user's SID (Security Identifier) - a unique, permanent ID assigned to each
# Windows account. Unlike a username, the SID never changes even if the profile is deleted and
# recreated. Using it as the key name lets us track setup state per user on shared machines.
# -FromInstall runs the per-user setup for the installing account during the install
# (invoked as the elevated interactive user from tweaks.yml). It does everything in one
# pass and writes the completion marker directly: the install reboot replaces the logoff,
# so the first logon lands on a fully configured desktop with no RunOnce cycle.
param([switch]$FinalizeSearch, [switch]$FromInstall)

# The first-logon console closes with the session, so keep a per-user transcript of
# every run (including the hidden -FinalizeSearch pass) for reviewing warnings later.
try
{
    $transcriptDir = Join-Path -Path $env:LOCALAPPDATA -ChildPath 'AtlasOS\Logs'
    if (-not (Test-Path -LiteralPath $transcriptDir))
    {
        $null = New-Item -Path $transcriptDir -ItemType Directory -Force
    }
    $transcriptName = '{0:yyyyMMdd-HHmmss}-new-user-setup-{1}.log' -f (Get-Date), $PID
    Start-Transcript -Path (Join-Path -Path $transcriptDir -ChildPath $transcriptName) | Out-Null
} catch
{
    $null = $_
}

$sid = [System.Security.Principal.WindowsIdentity]::GetCurrent().User.Value
$machineMarkerPath = 'HKLM:\SOFTWARE\AtlasOS\UserSetup'
$userMarkerPath = 'HKCU:\SOFTWARE\AtlasOS\UserSetup'

function Get-SetupMarker
{
    foreach ($path in @($machineMarkerPath, $userMarkerPath))
    {
        try
        {
            $value = Get-ItemPropertyValue -Path $path -Name $sid -ErrorAction Stop
            return [int]$value
        } catch
        {
            continue
        }
    }

    return 0
}

function Test-SetupMarker
{
    return (Get-SetupMarker) -ge 2
}

function Set-SetupMarker
{
    param([ValidateSet(1, 2)][int]$Value = 2)

    $errors = @()

    foreach ($path in @($machineMarkerPath, $userMarkerPath))
    {
        try
        {
            # Create only when missing: New-Item -Force recreates an existing key and wipes
            # the ACL add-newUser-script.ps1 granted (Users:SetValue on the HKLM marker),
            # which would lock standard users out of the machine marker and defeat the
            # profile-reset logoff-loop safeguard on 24H2/25H2.
            if (-not (Test-Path -LiteralPath $path))
            {
                $null = New-Item -Path $path -Force -ErrorAction Stop
            }
            Set-ItemProperty -Path $path -Name $sid -Value $Value -Type DWord -Force -ErrorAction Stop
            return
        } catch
        {
            $errors += "'$path': $($_.Exception.Message)"
        }
    }

    Write-Warning "Failed to write setup marker for SID '$sid'. $($errors -join '; ')"
}

function Set-NewUsersRunOnce
{
    $runOncePath = 'HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\RunOnce'
    $command = 'powershell -EP RemoteSigned -NoP & """$([Environment]::GetFolderPath(''Windows''))\AtlasModules\Scripts\Initialize-NewUser.ps1"""'

    # Don't -Force an existing RunOnce/Search key: that recreates it empty and drops any
    # other pending entries or user values. Create only when the key is missing.
    if (-not (Test-Path -LiteralPath $runOncePath))
    {
        $null = New-Item -Path $runOncePath -Force -ErrorAction Stop
    }
    Set-ItemProperty -Path $runOncePath -Name 'RunScript' -Value $command -Type String -Force -ErrorAction Stop
}

function Set-SearchTaskbarMode
{
    $searchPath = 'HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Search'
    $searchSettingsPath = 'HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\SearchSettings'
    $explorerPolicyPath = 'HKCU:\SOFTWARE\Policies\Microsoft\Windows\Explorer'

    # Windows pre-populates these keys with defaults; -Force would wipe them, so create
    # only when missing.
    if (-not (Test-Path -LiteralPath $searchPath))
    {
        $null = New-Item -Path $searchPath -Force -ErrorAction Stop
    }
    if (-not (Test-Path -LiteralPath $searchSettingsPath))
    {
        $null = New-Item -Path $searchSettingsPath -Force -ErrorAction Stop
    }

    Set-ItemProperty -Path $searchPath -Name 'SearchboxTaskbarMode' -Value 1 -Type DWord -Force -ErrorAction Stop
    Set-ItemProperty -Path $searchPath -Name 'SearchboxTaskbarModeCache' -Value 1 -Type DWord -Force -ErrorAction Stop
    Set-ItemProperty -Path $searchSettingsPath -Name 'IsAADCloudSearchEnabled' -Value 0 -Type DWord -Force -ErrorAction Stop
    Set-ItemProperty -Path $searchSettingsPath -Name 'IsDeviceSearchHistoryEnabled' -Value 0 -Type DWord -Force -ErrorAction Stop
    Set-ItemProperty -Path $searchSettingsPath -Name 'IsDynamicSearchBoxEnabled' -Value 0 -Type DWord -Force -ErrorAction Stop
    Set-ItemProperty -Path $searchSettingsPath -Name 'IsMSACloudSearchEnabled' -Value 0 -Type DWord -Force -ErrorAction Stop
    $suggestionsPolicy = $null
    try
    {
        $suggestionsPolicy = Get-ItemPropertyValue -Path $explorerPolicyPath -Name 'DisableSearchBoxSuggestions' -ErrorAction Stop
    } catch
    {
        $suggestionsPolicy = $null
    }

    if ($suggestionsPolicy -ne 1)
    {
        try
        {
            if (-not (Test-Path -LiteralPath $explorerPolicyPath))
            {
                $null = New-Item -Path $explorerPolicyPath -Force -ErrorAction Stop
            }
            Set-ItemProperty -Path $explorerPolicyPath -Name 'DisableSearchBoxSuggestions' -Value 1 -Type DWord -Force -ErrorAction Stop
        } catch
        {
            Write-Warning "Couldn't write optional search policy '$explorerPolicyPath': $($_.Exception.Message)"
        }
    }
}

function Start-DelayedSearchFinalizer
{
    $scriptPath = Join-Path -Path ([Environment]::GetFolderPath('Windows')) -ChildPath 'AtlasModules\Scripts\Initialize-NewUser.ps1'
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

function Set-AtlasTaskbarPins
{
    param([AllowNull()][string]$Browser)

    $taskbarPinsScript = Join-Path -Path $atlasModules -ChildPath 'Scripts\Internal\Set-TaskbarPins.ps1'
    if (!(Test-Path -LiteralPath $taskbarPinsScript -PathType Leaf))
    {
        throw "Taskbar pins script '$taskbarPinsScript' was not found."
    }

    if ([string]::IsNullOrWhiteSpace($Browser))
    {
        & $taskbarPinsScript -CurrentUserOnly -NoExplorerStop
    } else
    {
        & $taskbarPinsScript -Browser $Browser -CurrentUserOnly -NoExplorerStop
    }
}

if ($FinalizeSearch)
{
    Start-Sleep -Seconds 20
    Set-SearchTaskbarMode
    Stop-Process -Name explorer -Force -ErrorAction SilentlyContinue
    Start-Sleep -Seconds 2
    Start-Process -FilePath explorer.exe -ErrorAction SilentlyContinue
    Start-Sleep -Seconds 5
    Set-SearchTaskbarMode
    exit
}

# -FromInstall ignores a completed marker: a reinstall should reconfigure the
# installing account, and with no logoff cycle there is no double-run to guard.
$setupMarker = if ($FromInstall)
{ 0 
} else
{ Get-SetupMarker 
}
if ($setupMarker -ge 2)
{
    exit
}

$windir = [Environment]::GetFolderPath('Windows')
& "$windir\AtlasModules\initPowerShell.ps1"
$atlasDesktop = "$windir\AtlasDesktop"
$atlasModules = "$windir\AtlasModules"

if (!(Test-Path $atlasDesktop) -or !(Test-Path $atlasModules))
{
    Write-Host "Atlas was about to configure user settings, but its files weren't found. :(" -ForegroundColor Red
    Read-Pause
    exit 1
}

if ($setupMarker -lt 1)
{
    $title = 'Preparing Atlas user settings...'
    $Host.UI.RawUI.WindowTitle = $title
    Write-Host $title -ForegroundColor Yellow
    Write-Host $('-' * ($title.length + 3)) -ForegroundColor Yellow
    if (-not $FromInstall)
    {
        Write-Host "You'll be logged out in 10 to 20 seconds, and once you login again, your new account will be ready for use."
    }

    $env:ATLAS_USER_CONTEXT = "1"
    try
    {
        # Disable Windows 11 context menu & 'Gallery' in File Explorer
        if ([System.Environment]::OSVersion.Version.Build -ge 22000)
        {
            & "$atlasDesktop\4. Interface Tweaks\Context Menus\Windows 11\Old Context Menu (default).cmd" /silent
            & "$atlasDesktop\4. Interface Tweaks\File Explorer Customization\Gallery\Disable Gallery (default).cmd" /silent

            # Set ThemeMRU (recent themes)
            Set-AtlasTheme -Path "$([Environment]::GetFolderPath('Windows'))\Resources\Themes\atlas-v0.5.x-dark.theme"
            Set-AtlasThemeMru | Out-Null

            # The theme sets the wallpaper (and WindowsSpotlight=0), but on Pro the Windows
            # Spotlight desktop provider selected at OOBE re-applies its cached image at
            # logon and overrides it. Force Picture mode + the Atlas wallpaper explicitly so
            # Spotlight can't re-own the desktop. PicturePosition=4 (Fill) -> WallpaperStyle 10.
            # CANDIDATE: verify on a VM that this survives the installer's post-reboot logon
            # (this path does not re-run once the setup marker is 2).
            try
            {
                $atlasWallpaper = Join-Path -Path $windir -ChildPath 'AtlasModules\Wallpapers\atlas-v0.5.x-dark.png'
                if (Test-Path -LiteralPath $atlasWallpaper)
                {
                    Set-ItemProperty -Path 'HKCU:\Control Panel\Desktop' -Name 'WallPaper' -Value $atlasWallpaper -Type String -Force
                    Set-ItemProperty -Path 'HKCU:\Control Panel\Desktop' -Name 'WallpaperStyle' -Value '10' -Type String -Force
                    Set-ItemProperty -Path 'HKCU:\Control Panel\Desktop' -Name 'TileWallpaper' -Value '0' -Type String -Force
                    $wallpapersKey = 'HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\Wallpapers'
                    if (-not (Test-Path -LiteralPath $wallpapersKey))
                    {
                        New-Item -Path $wallpapersKey -Force | Out-Null
                    }
                    # BackgroundType 0 = Picture (switches the desktop provider away from Spotlight).
                    Set-ItemProperty -Path $wallpapersKey -Name 'BackgroundType' -Value 0 -Type DWord -Force
                    if (-not ('Atlas.Wallpaper' -as [type]))
                    {
                        Add-Type -Namespace 'Atlas' -Name 'Wallpaper' -MemberDefinition @'
[System.Runtime.InteropServices.DllImport("user32.dll", CharSet = System.Runtime.InteropServices.CharSet.Auto, SetLastError = true)]
public static extern bool SystemParametersInfo(uint uiAction, uint uiParam, string pvParam, uint fWinIni);
'@
                    }
                    # SPI_SETDESKWALLPAPER = 0x14; SPIF_UPDATEINIFILE | SPIF_SENDCHANGE = 0x03.
                    [Atlas.Wallpaper]::SystemParametersInfo(0x14, 0, $atlasWallpaper, 0x03) | Out-Null
                }
            } catch
            {
                Write-Warning "Failed to force the Atlas desktop wallpaper: $($_.Exception.Message)"
            }

            # Re-pin Music & Videos to File Explorer Home (they drop off once recent files
            # are disabled). Shell COM against the running explorer, so it runs here at
            # first logon rather than from the SYSTEM install phase.
            try
            {
                & (Join-Path -Path ([Environment]::GetFolderPath('Windows')) -ChildPath 'AtlasModules\Scripts\Tasks\Add-MusicVideosToHome.ps1')
            } catch
            {
                Write-Warning "Failed to pin Music & Videos to Home: $($_.Exception.Message)"
            }
        }

        try
        {
            Set-AtlasLockscreenImage
        } catch
        {
            Write-Warning "Failed to set lockscreen image: $($_.Exception.Message)"
        }

        # Block Store search recommendations for this user. Runs here (not from the
        # SYSTEM tweak phase) so LocalApplicationData resolves to the real user profile.
        try
        {
            & (Join-Path -Path $atlasModules -ChildPath 'Scripts\Tasks\Disable-StoreSearchRecommendations.ps1')
        } catch
        {
            Write-Warning "Failed to block Store search recommendations: $($_.Exception.Message)"
        }

        & "$atlasDesktop\3. General Configuration\File Sharing\Network Navigation Pane\Disable Network Navigation Pane (default).cmd" /silent
        & "$atlasDesktop\4. Interface Tweaks\File Explorer Customization\Automatic Folder Discovery\Disable Automatic Folder Discovery (default).cmd" /silent
        & "$atlasDesktop\4. Interface Tweaks\Visual Effects (Animations)\Atlas Visual Effects (default).cmd" /silent
    } finally
    {
        Remove-Item "Env:\ATLAS_USER_CONTEXT" -ErrorAction SilentlyContinue
    }
}

# Set taskbar pins
$browser = $null
$setupOptionsPath = "HKLM:\SOFTWARE\AtlasOS\SetupOptions"
$allowedBrowsers = @("Brave", "Firefox", "LibreWolf", "Google Chrome", "Microsoft Edge")

try
{
    $browser = Get-ItemPropertyValue -Path $setupOptionsPath -Name "Browser" -ErrorAction Stop
} catch
{
    Write-Warning "Couldn't read browser selection from '$setupOptionsPath'. Falling back to default taskbar pins."
}

if (![string]::IsNullOrWhiteSpace($browser) -and $browser -notin $allowedBrowsers)
{
    Write-Warning "Invalid browser value '$browser' found in '$setupOptionsPath'. Falling back to default taskbar pins."
    $browser = $null
}

if ([string]::IsNullOrWhiteSpace($browser))
{
    $browser = $null
}

Set-AtlasTaskbarPins -Browser $browser
Set-SearchTaskbarMode

if ($FromInstall)
{
    Set-SetupMarker -Value 2
    exit
}

if ($setupMarker -lt 1)
{
    Set-SetupMarker -Value 1
    Set-NewUsersRunOnce
    Start-Sleep 5
    logoff
    exit
}

# Write the completion marker for this user so the guard above exits early on any future re-run.
Stop-Process -Name explorer -Force -ErrorAction SilentlyContinue
# Explorer needs a moment to fully tear down before relaunching, or the new instance
# doesn't recognize itself as the shell and opens as a plain window instead.
Start-Sleep -Seconds 2
Set-SearchTaskbarMode
Set-SetupMarker -Value 2

Start-Process -FilePath explorer.exe -ErrorAction SilentlyContinue
Start-DelayedSearchFinalizer
