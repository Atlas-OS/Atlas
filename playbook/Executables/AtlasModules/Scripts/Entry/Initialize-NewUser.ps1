# User setup state belongs to the current user's HKCU hive. The old shared HKLM
# marker is untrusted and is cleaned up by the add-newUser-script tweak.
[CmdletBinding()]
param(
    [switch]$FinalizeSearch,
    [switch]$FromInstall,
    [string]$ExpectedUserSid
)

$ErrorActionPreference = 'Stop'
$sid = [Security.Principal.WindowsIdentity]::GetCurrent().User.Value
$windir = [Environment]::GetFolderPath('Windows')
$markerSubKey = 'SOFTWARE\AtlasOS\UserSetup'
$markerPath = "HKCU:\$markerSubKey"

if ($FinalizeSearch -and $FromInstall) {
    throw 'FinalizeSearch and FromInstall are mutually exclusive.'
}

if ($FromInstall) {
    if ([string]::IsNullOrWhiteSpace($ExpectedUserSid)) {
        throw 'Install setup requires the install-state user SID.'
    }

    try {
        $expectedSid = (New-Object Security.Principal.SecurityIdentifier($ExpectedUserSid)).Value
    }
    catch {
        throw "The expected installing-user SID '$ExpectedUserSid' is invalid."
    }

    if ($sid -cne $expectedSid) {
        throw "Initialize-NewUser token SID '$sid' does not match install-state SID '$expectedSid'."
    }
}
elseif (-not [string]::IsNullOrWhiteSpace($ExpectedUserSid)) {
    throw 'ExpectedUserSid is valid only with FromInstall.'
}

function Get-SetupMarker {
    $key = [Microsoft.Win32.Registry]::CurrentUser.OpenSubKey($markerSubKey, $false)
    if ($null -eq $key) {
        return 0
    }

    try {
        if (@($key.GetValueNames()) -cnotcontains $sid -or
            $key.GetValueKind($sid) -ne [Microsoft.Win32.RegistryValueKind]::DWord) {
            return 0
        }

        $value = $key.GetValue(
            $sid,
            $null,
            [Microsoft.Win32.RegistryValueOptions]::DoNotExpandEnvironmentNames
        )
        if ($value -is [int]) {
            return [int]$value
        }
        return 0
    }
    finally {
        $key.Dispose()
    }
}

function Set-SetupMarker {
    param([Parameter(Mandatory)][ValidateSet(1, 2)][int]$Value)

    if (-not (Test-Path -LiteralPath $markerPath)) {
        $null = New-Item -Path $markerPath -Force
    }
    Set-ItemProperty -Path $markerPath -Name $sid -Value $Value -Type DWord -Force
}

# First-logon windows close with the session, so retain warnings in a per-user log.
# The delayed search finalizer is intentionally silent and does not need a second
# transcript containing only its process header.
if (-not $FinalizeSearch) {
    try {
        $transcriptDir = Join-Path $env:LOCALAPPDATA 'AtlasOS\Logs'
        $null = New-Item -Path $transcriptDir -ItemType Directory -Force
        $transcriptName = '{0:yyyyMMdd-HHmmss}-new-user-setup-{1}.log' -f (Get-Date), $PID
        Start-Transcript -Path (Join-Path $transcriptDir $transcriptName) | Out-Null
    }
    catch {
        $null = $_
    }
}

function Set-SearchTaskbarMode {
    $searchPath = 'HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Search'
    $settingsPath = 'HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\SearchSettings'
    foreach ($path in @($searchPath, $settingsPath)) {
        if (-not (Test-Path -LiteralPath $path)) {
            $null = New-Item -Path $path -Force
        }
    }

    Set-ItemProperty -Path $searchPath -Name SearchboxTaskbarMode -Value 1 -Type DWord -Force
    Set-ItemProperty -Path $searchPath -Name SearchboxTaskbarModeCache -Value 1 -Type DWord -Force
    Set-ItemProperty -Path $settingsPath -Name IsAADCloudSearchEnabled -Value 0 -Type DWord -Force
    Set-ItemProperty -Path $settingsPath -Name IsDeviceSearchHistoryEnabled -Value 0 -Type DWord -Force
    Set-ItemProperty -Path $settingsPath -Name IsDynamicSearchBoxEnabled -Value 0 -Type DWord -Force
    Set-ItemProperty -Path $settingsPath -Name IsMSACloudSearchEnabled -Value 0 -Type DWord -Force
}

function Set-AtlasFirstLogonPreferences {
    # Windows profile creation does not retain every default-hive preference.
    # Repair only the observed omissions in the affected user's own session.
    # Recorded choices are handled by Invoke-AtlasToggleUserReapply instead.
    if ((Test-AtlasSystem) -or (Test-AtlasAdmin)) {
        throw 'First-logon preferences require the affected user''s non-elevated context.'
    }

    $preferences = @(
        @{ Toggle = 'BackgroundApps'; Path = 'HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\BackgroundAccessApplications'; Name = 'GlobalUserDisabled'; Value = 1 }
        @{ Toggle = 'Home'; Path = 'HKCU:\Software\Classes\CLSID\{f874310e-b6b7-47dc-bc84-b9e6b38f5903}'; Name = 'System.IsPinnedToNameSpaceTree'; Value = 0 }
        @{ Toggle = 'WindowsSpotlight'; Path = 'HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\ContentDeliveryManager'; Name = 'ContentDeliveryAllowed'; Value = 0 }
    )
    foreach ($preference in $preferences) {
        $record = Get-AtlasToggleState -Name $preference.Toggle
        if ($null -ne $record -and $null -ne $record.State) {
            continue
        }
        if (-not (Test-Path -LiteralPath $preference.Path)) {
            $null = New-Item -Path $preference.Path -Force
        }
        Set-ItemProperty -LiteralPath $preference.Path -Name $preference.Name `
            -Value $preference.Value -Type DWord -Force
    }
}

function Invoke-CurrentSessionExplorerRefresh {
    $sessionId = [Diagnostics.Process]::GetCurrentProcess().SessionId
    foreach ($explorer in @(Get-Process -Name explorer -ErrorAction SilentlyContinue)) {
        try {
            if ($explorer.SessionId -eq $sessionId) {
                Stop-Process -InputObject $explorer -Force -ErrorAction SilentlyContinue
            }
        }
        catch {
            # Explorer can exit between enumeration and the session check.
            $null = $_
        }
    }
}

function Start-DelayedSearchFinalizer {
    $vbsPath = Join-Path $windir 'AtlasModules\Scripts\Entry\Invoke-InitializeNewUserHidden.vbs'
    $wscriptPath = Join-Path ([Environment]::SystemDirectory) 'wscript.exe'
    Start-Process -FilePath $wscriptPath `
        -ArgumentList @("`"$vbsPath`"", '-FinalizeSearch')
}

if ($FinalizeSearch) {
    Start-Sleep -Seconds 20
    Set-SearchTaskbarMode
    Invoke-CurrentSessionExplorerRefresh
    Start-Sleep -Seconds 5
    Set-SearchTaskbarMode
    # The Atlas app records where it lives when it starts an install; open its
    # completion window. Otherwise (installed from the command line, or the app
    # has moved) a toast that stays on screen says the same thing.
    $opened = $false
    try {
        $launcherPath = Join-Path -Path ([Environment]::GetFolderPath('LocalApplicationData')) -ChildPath 'AtlasOS\App\launcher.json'
        if ([IO.File]::Exists($launcherPath)) {
            $launcher = [IO.File]::ReadAllText($launcherPath) | ConvertFrom-Json
            $appExe = [string]$launcher.exe
            if ($appExe -and [IO.File]::Exists($appExe)) {
                Start-Process -FilePath $appExe -ArgumentList '--just-installed' -WorkingDirectory ([IO.Path]::GetDirectoryName($appExe))
                $opened = $true
            }
        }
    }
    catch {
        Write-Warning "Failed to open the Atlas app: $($_.Exception.Message)"
    }
    if (-not $opened) {
        try {
            # Stays on screen until dismissed: the user may have left the PC to install.
            & (Join-Path $windir 'AtlasModules\Scripts\Operations\Show-AtlasToast.ps1') `
                -Title Atlas -Message 'Atlas is installed and your PC is ready to use.' -Persistent
        }
        catch {
            Write-Warning "Failed to show the completion toast: $($_.Exception.Message)"
        }
    }
    return
}

# Reinstalls deliberately reapply the installing user's configuration.
$setupMarker = if ($FromInstall) { 0 } else { Get-SetupMarker }
if ($setupMarker -ge 2) {
    return
}

# RunOnce deletes its value before launching. Requeue the current stage first so a
# required setup failure is retried at the next logon instead of stranding the account.
$runOncePath = 'HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\RunOnce'
if (-not $FromInstall) {
    if (-not (Test-Path -LiteralPath $runOncePath)) {
        $null = New-Item -Path $runOncePath -Force
    }
    $runOnceCommand = '"%windir%\System32\wscript.exe" "%windir%\AtlasModules\Scripts\Entry\Invoke-InitializeNewUserHidden.vbs"'
    Set-ItemProperty -Path $runOncePath -Name RunScript -Value $runOnceCommand -Type ExpandString -Force
}

$atlasModules = Join-Path $windir 'AtlasModules'
$atlasDesktop = Join-Path $windir 'AtlasDesktop'
$initializer = Join-Path $atlasModules 'Scripts\Initialize-AtlasPowerShell.ps1'
if (-not (Test-Path -LiteralPath $atlasModules -PathType Container) -or
    -not (Test-Path -LiteralPath $atlasDesktop -PathType Container) -or
    -not (Test-Path -LiteralPath $initializer -PathType Leaf)) {
    throw 'Atlas user-setup files are missing from the Windows directory.'
}
. $initializer
$modulesRoot = Join-Path $atlasModules 'Scripts\Modules'
# Atlas.Core carries Initialize-AtlasNativeType, the single native compile entry point.
foreach ($moduleName in @('Atlas.Core', 'Atlas.Shortcuts', 'Atlas.Themes', 'Atlas.Toggles', 'Atlas.Shell')) {
    $moduleManifest = Join-Path $modulesRoot "$moduleName\$moduleName.psd1"
    if (-not (Test-Path -LiteralPath $moduleManifest -PathType Leaf)) {
        throw "The required user-setup module '$moduleName' is missing at '$moduleManifest'."
    }
    Import-Module -Name $moduleManifest -Force -ErrorAction Stop
}

$desktopPath = [Environment]::GetFolderPath('DesktopDirectory')
if ([string]::IsNullOrWhiteSpace($desktopPath) -or
    -not (Test-Path -LiteralPath $desktopPath -PathType Container)) {
    throw "The current user's Desktop directory is unavailable."
}
$atlasFolderIcon = Join-Path $atlasModules 'Other\atlas-folder.ico'
if (-not (Test-Path -LiteralPath $atlasFolderIcon -PathType Leaf)) {
    throw "The Atlas folder icon is missing at '$atlasFolderIcon'."
}
New-AtlasShortcut -Source $atlasDesktop `
    -Destination (Join-Path $desktopPath 'Atlas.lnk') `
    -Icon "$atlasFolderIcon,0"

function Invoke-AtlasDesktopCommand {
    param([Parameter(Mandatory)][string]$RelativePath)

    $path = Join-Path $atlasDesktop $RelativePath
    if (-not (Test-Path -LiteralPath $path -PathType Leaf)) {
        throw "Atlas desktop command '$path' was not found."
    }

    # Setup owns the final shell refresh. A nested toggle must not restart Explorer
    # while the RunOnce retry is still armed, which can launch setup concurrently.
    & $path /silent /noaction
    if ($LASTEXITCODE -ne 0) {
        throw "Atlas desktop command '$path' exited with code $LASTEXITCODE."
    }
}

if (-not $FromInstall) {
    try {
        & (Join-Path $atlasModules 'Scripts\Operations\Remove-OneDriveCurrentUserData.ps1') `
            -ExpectedUserSid $sid
    }
    catch {
        Write-Warning "Failed to remove current-user OneDrive leftovers: $($_.Exception.Message)"
    }
    $uninstallEdgeFlag = Join-Path $atlasModules 'Flags\option-uninstall-edge.flag'
    if (Test-Path -LiteralPath $uninstallEdgeFlag -PathType Leaf) {
        try {
            & (Join-Path $atlasModules 'Scripts\Operations\Remove-EdgeCurrentUserData.ps1') `
                -ExpectedUserSid $sid
        }
        catch {
            Write-Warning "Failed to remove current-user Edge leftovers: $($_.Exception.Message)"
        }
    }
    try {
        & (Join-Path $atlasModules 'Scripts\Operations\Initialize-AtlasLibreWolfUser.ps1') `
            -ExpectedUserSid $sid
    }
    catch {
        Write-Warning "Failed to initialize LibreWolf for the current user: $($_.Exception.Message)"
    }

    [void](Set-AtlasFileAssociations -AssociationProfile Base -ExpectedUserSid $sid)

    Set-AtlasSendToContextMenu -DebloatDefaults -ExpectedUserSid $sid
}

if ($setupMarker -lt 1) {
    if (-not $FromInstall) {
        try {
            & (Join-Path $atlasModules 'Scripts\Operations\Show-AtlasToast.ps1') `
                -Title Atlas `
                -Message 'Finishing setup. Your desktop may briefly flash.'
        }
        catch {
            Write-Warning "Failed to show the setup toast: $($_.Exception.Message)"
        }
    }

    $env:ATLAS_USER_CONTEXT = '1'
    try {
        if ([Environment]::OSVersion.Version.Build -ge 22000) {
            Invoke-AtlasDesktopCommand '4. Interface Tweaks\Context Menus\Windows 11\Old Context Menu (default).cmd'
            Invoke-AtlasDesktopCommand '4. Interface Tweaks\File Explorer Customization\Gallery\Disable Gallery (default).cmd'

            Set-AtlasTheme -Path (Join-Path $windir 'Resources\Themes\atlas-v0.5.x-dark.theme')
            Set-AtlasThemeMru | Out-Null

            try {
                $wallpaper = Join-Path $atlasModules 'Wallpapers\atlas-v0.5.x-dark.png'
                if (Test-Path -LiteralPath $wallpaper -PathType Leaf) {
                    Set-ItemProperty -Path 'HKCU:\Control Panel\Desktop' -Name WallPaper -Value $wallpaper -Type String -Force
                    Set-ItemProperty -Path 'HKCU:\Control Panel\Desktop' -Name WallpaperStyle -Value '10' -Type String -Force
                    Set-ItemProperty -Path 'HKCU:\Control Panel\Desktop' -Name TileWallpaper -Value '0' -Type String -Force

                    $wallpapersKey = 'HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\Wallpapers'
                    if (-not (Test-Path -LiteralPath $wallpapersKey)) {
                        $null = New-Item -Path $wallpapersKey -Force
                    }
                    Set-ItemProperty -Path $wallpapersKey -Name BackgroundType -Value 0 -Type DWord -Force

                    Initialize-AtlasNativeType
                    [Atlas.Native.Wallpaper]::SystemParametersInfo(
                        0x14, 0, $wallpaper, 0x03) | Out-Null
                }
            }
            catch {
                Write-Warning "Failed to set the Atlas wallpaper: $($_.Exception.Message)"
            }

            try {
                Add-AtlasMusicVideosToHome
            }
            catch {
                Write-Warning "Failed to pin Music and Videos to Home: $($_.Exception.Message)"
            }
        }

        try {
            Set-AtlasLockscreenImage
        }
        catch {
            Write-Warning "Failed to set the lock-screen image: $($_.Exception.Message)"
        }

        try {
            Import-Module -Name (Join-Path $modulesRoot 'Atlas.Search\Atlas.Search.psd1') -Force -ErrorAction Stop
            Disable-AtlasStoreSearchRecommendations
        }
        catch {
            Write-Warning "Failed to block Store search recommendations: $($_.Exception.Message)"
        }

        Invoke-AtlasDesktopCommand '3. General Configuration\File Sharing\Network Navigation Pane\Disable Network Navigation Pane (default).cmd'
        Invoke-AtlasDesktopCommand '4. Interface Tweaks\File Explorer Customization\Automatic Folder Discovery\Disable Automatic Folder Discovery (default).cmd'
        Invoke-AtlasDesktopCommand '4. Interface Tweaks\Visual Effects (Animations)\Atlas Visual Effects (default).cmd'
    }
    finally {
        Remove-Item Env:\ATLAS_USER_CONTEXT -ErrorAction SilentlyContinue
    }
}

$browser = $null
$setupOptionsPath = 'HKLM:\SOFTWARE\AtlasOS\SetupOptions'
try {
    $browser = Get-ItemPropertyValue -Path $setupOptionsPath -Name Browser
}
catch {
    Write-Warning "Couldn't read the browser selection. Using default taskbar pins."
}

$allowedBrowsers = @('Brave', 'Firefox', 'LibreWolf', 'Google Chrome', 'Microsoft Edge')
if (-not [string]::IsNullOrWhiteSpace($browser) -and $browser -notin $allowedBrowsers) {
    Write-Warning "Ignoring unknown browser selection '$browser'."
    $browser = $null
}

$pinArguments = @{
    NoExplorerStop = $true
}
if (-not [string]::IsNullOrWhiteSpace($browser)) {
    $pinArguments['Browser'] = $browser
}
Set-AtlasTaskbarPins @pinArguments
if (-not $FromInstall) {
    Set-AtlasFirstLogonPreferences
}
Invoke-AtlasToggleUserReapply
Set-SearchTaskbarMode

# Apply this after theme setup, which can overwrite registry-only High Contrast
# flags with the session's cached settings. The API preserves the feature itself.
Initialize-AtlasNativeType
[Atlas.Native.HighContrastShortcut]::DisableForCurrentUser()

if ($FromInstall) {
    Set-SetupMarker -Value 2
    # Set-AtlasTaskbarPins keeps Explorer alive while it atomically replaces the pin
    # files and Taskband values. Refresh this user's shell only after every
    # install-time user action is complete so the running Explorer window adopts
    # the canonical File Explorer pin instead of appearing as a duplicate icon.
    Invoke-CurrentSessionExplorerRefresh
    return
}

Set-SetupMarker -Value 2
# RunOnce deletes a value before starting it, and this script requeues the value
# while setup is incomplete. Remove that retry before restarting Explorer; otherwise
# the new shell can launch a concurrent copy before this process reaches cleanup.
Remove-ItemProperty -Path $runOncePath -Name RunScript -ErrorAction SilentlyContinue
Invoke-CurrentSessionExplorerRefresh
Start-Sleep -Seconds 3
Set-SearchTaskbarMode
Start-DelayedSearchFinalizer
