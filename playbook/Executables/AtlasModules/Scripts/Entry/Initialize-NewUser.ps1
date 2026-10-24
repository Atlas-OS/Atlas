# User setup state belongs to the current user's HKCU hive. The old shared HKLM
# marker is untrusted and is cleaned up by the add-newUser-script tweak.
[CmdletBinding()]
param(
    [switch]$FinalizeSearch,
    [switch]$FromInstall,
    [switch]$RefreshStart,
    [string]$ExpectedUserSid
)

# Setup starts with the user's own environment, so pin module resolution before the
# first autoloaded command. A missing bootstrap stops setup further down, after the
# RunOnce retry is queued again.
$bootstrap = [IO.Path]::Combine([Environment]::GetFolderPath('Windows'), 'AtlasModules', 'Scripts', 'Initialize-AtlasPowerShell.ps1')
if ([IO.File]::Exists($bootstrap)) { . $bootstrap }

$ErrorActionPreference = 'Stop'
$sid = [Security.Principal.WindowsIdentity]::GetCurrent().User.Value
$windir = [Environment]::GetFolderPath('Windows')
$markerSubKey = 'SOFTWARE\AtlasOS\UserSetup'
$markerPath = "HKCU:\$markerSubKey"

if (($FinalizeSearch -and $FromInstall) -or ($RefreshStart -and ($FinalizeSearch -or $FromInstall))) {
    throw 'FinalizeSearch, FromInstall and RefreshStart are mutually exclusive.'
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
    Import-Module -Name (Join-Path $windir 'AtlasModules\Scripts\Modules\Atlas.Registry\Atlas.Registry.psd1') -ErrorAction Stop
    $null = Initialize-AtlasRegistryIdentityContext -CurrentToken -ExpectedUserSid $sid
    $searchPath = 'HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Search'
    $settingsPath = 'HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\SearchSettings'
    foreach ($path in @($searchPath, $settingsPath)) {
        if (-not (Test-Path -LiteralPath $path)) {
            $null = New-Item -Path $path -Force
        }
    }

    # Follow a recorded 'Enable Web Search' choice, which the replay has applied: the
    # search box with highlights, and none of the cloud-search values it removed. The
    # delayed finalizer doesn't load Atlas.Toggles, so read the record directly.
    $webSearch = (Get-ItemProperty -Path 'HKLM:\SOFTWARE\AtlasOS\Services\WebSearch' -Name state `
            -ErrorAction SilentlyContinue).state
    if ($webSearch -is [int] -and $webSearch -eq 1) {
        $mode = 2
        $entries = @(@{ Path = $settingsPath; Name = 'IsDynamicSearchBoxEnabled'; Type = 'DWord'; Data = 1; AllowOsProtected = $true })
    }
    else {
        $mode = 1
        $entries = foreach ($name in @('IsAADCloudSearchEnabled', 'IsDeviceSearchHistoryEnabled', 'IsDynamicSearchBoxEnabled', 'IsMSACloudSearchEnabled')) {
            @{ Path = $settingsPath; Name = $name; Type = 'DWord'; Data = 0; AllowOsProtected = $true }
        }
    }

    Set-ItemProperty -Path $searchPath -Name SearchboxTaskbarMode -Value $mode -Type DWord -Force
    Set-ItemProperty -Path $searchPath -Name SearchboxTaskbarModeCache -Value $mode -Type DWord -Force
    # Keep finalization running when Windows refuses an individual preference.
    Invoke-AtlasRegistryEntries -Entries $entries -Scope CurrentUser -IsArm64 $false
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

# Start's Category view records one Category value per app under this key and
# never revisits an app that has no entry. At the installing account's first
# sign-in after the restart, Windows is still deregistering the packages the
# install removed while the shell builds Start for the first time, so Start
# categorises only the apps it can enumerate through that churn and the rest sit
# in "Other" for good. Removing the whole key makes the next Start host redo every
# app in one pass; pins live elsewhere and are untouched.
$startCategoriesPath = 'HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Start\TileProperties'
$startRefreshRunPath = 'HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Run'
$startRefreshRunName = 'AtlasStartCategories'
$startRefreshBootName = 'StartRefreshBoot'

function Get-BootStamp {
    return (Get-CimInstance -ClassName Win32_OperatingSystem -ErrorAction Stop).LastBootUpTime.ToUniversalTime().ToString('o')
}

function Register-StartCategoryRefresh {
    # Run, not RunOnce: the install-time Explorer restart consumes RunOnce within the
    # same boot. The stage compares the boot recorded here and acts only after a restart.
    if (-not (Test-Path -LiteralPath $markerPath)) {
        $null = New-Item -Path $markerPath -Force
    }
    Set-ItemProperty -Path $markerPath -Name $startRefreshBootName -Value (Get-BootStamp) -Type String -Force
    if (-not (Test-Path -LiteralPath $startRefreshRunPath)) {
        $null = New-Item -Path $startRefreshRunPath -Force
    }
    $command = '"%windir%\System32\wscript.exe" "%windir%\AtlasModules\Scripts\Entry\Invoke-InitializeNewUserHidden.vbs" -RefreshStart'
    Set-ItemProperty -Path $startRefreshRunPath -Name $startRefreshRunName -Value $command -Type ExpandString -Force
}

function Reset-StartCategories {
    Remove-Item -Path $startCategoriesPath -Recurse -Force -ErrorAction SilentlyContinue
    $sessionId = [Diagnostics.Process]::GetCurrentProcess().SessionId
    foreach ($startHost in @(Get-Process -Name StartMenuExperienceHost -ErrorAction SilentlyContinue)) {
        if ($startHost.SessionId -eq $sessionId) {
            Stop-Process -InputObject $startHost -Force -ErrorAction SilentlyContinue
        }
    }
}

function Start-DelayedSearchFinalizer {
    $vbsPath = Join-Path $windir 'AtlasModules\Scripts\Entry\Invoke-InitializeNewUserHidden.vbs'
    $wscriptPath = Join-Path ([Environment]::SystemDirectory) 'wscript.exe'
    Start-Process -FilePath $wscriptPath `
        -ArgumentList @("`"$vbsPath`"", '-FinalizeSearch')
}

if ($RefreshStart) {
    $recordedBoot = (Get-ItemProperty -Path $markerPath -Name $startRefreshBootName -ErrorAction SilentlyContinue).$startRefreshBootName
    if ($recordedBoot -and $recordedBoot -ceq (Get-BootStamp)) {
        return
    }
    Remove-ItemProperty -Path $startRefreshRunPath -Name $startRefreshRunName -ErrorAction SilentlyContinue
    Remove-ItemProperty -Path $markerPath -Name $startRefreshBootName -ErrorAction SilentlyContinue
    # Start's package churn settles about 10 s after sign-in; 60 s leaves room for
    # slow disks.
    Start-Sleep -Seconds 60
    Reset-StartCategories
    return
}

if ($FinalizeSearch) {
    Start-Sleep -Seconds 20
    Reset-StartCategories
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

function Test-BuiltInAdministrator {
    return [Security.Principal.WindowsIdentity]::GetCurrent().User.IsWellKnown(
        [Security.Principal.WellKnownSidType]::AccountAdministratorSid
    )
}

function Test-FullAdministratorToken {
    $principal = New-Object Security.Principal.WindowsPrincipal([Security.Principal.WindowsIdentity]::GetCurrent())
    return $principal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
}

# Returns $null when this token can run user setup, otherwise why it can't: UacOff,
# which turning on UAC fixes, or BuiltInAdministrator, which it doesn't unless Admin
# Approval Mode covers that account too (FilterAdministratorToken).
function Get-UserSetupTokenBlock {
    if (-not (Test-FullAdministratorToken)) { return $null }
    $systemPolicyPath = 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System'
    $builtInAdministrator = (Test-BuiltInAdministrator) -and
        (Get-ItemProperty -Path $systemPolicyPath -Name FilterAdministratorToken `
            -ErrorAction SilentlyContinue).FilterAdministratorToken -ne 1
    $enableLua = (Get-ItemProperty -Path $systemPolicyPath -Name EnableLUA -ErrorAction SilentlyContinue).EnableLUA
    if (-not $builtInAdministrator -and $enableLua -ne 1) { return 'UacOff' }
    return 'BuiltInAdministrator'
}

# User setup needs this account's standard token, but the built-in Administrator, and
# any administrator while UAC is off, signs in with a full one that the user-only steps
# below refuse. Say why and stop; retry at later sign-ins only when turning UAC on fixes it.
$tokenBlock = if ($FromInstall) { $null } else { Get-UserSetupTokenBlock }

# RunOnce deletes its value before launching. Requeue the current stage first so a
# required setup failure is retried at the next logon instead of stranding the account.
$runOncePath = 'HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\RunOnce'
if (-not $FromInstall -and $tokenBlock -ne 'BuiltInAdministrator') {
    if (-not (Test-Path -LiteralPath $runOncePath)) {
        $null = New-Item -Path $runOncePath -Force
    }
    $runOnceCommand = '"%windir%\System32\wscript.exe" "%windir%\AtlasModules\Scripts\Entry\Invoke-InitializeNewUserHidden.vbs"'
    Set-ItemProperty -Path $runOncePath -Name RunScript -Value $runOnceCommand -Type ExpandString -Force
}

if ($null -ne $tokenBlock) {
    if ($tokenBlock -eq 'UacOff') {
        Write-Warning ('Atlas skipped user setup for this account: User Account Control (UAC) is off, so it has a full administrator token, and setup needs a standard user token. ' +
            'Turn on UAC and restart Windows; setup runs again at the next sign-in.')
    }
    else {
        Write-Warning ('Atlas skipped user setup for this account: the built-in Administrator account has a full administrator token, and setup needs a standard user token. ' +
            "Use another account to get Atlas's user settings.")
    }
    return
}

$atlasModules = Join-Path $windir 'AtlasModules'
$atlasDesktop = Join-Path $windir 'AtlasDesktop'
if (-not (Test-Path -LiteralPath $atlasModules -PathType Container) -or
    -not (Test-Path -LiteralPath $atlasDesktop -PathType Container) -or
    -not [IO.File]::Exists($bootstrap)) {
    throw 'Atlas user-setup files are missing from the Windows directory.'
}
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

    Set-AtlasFileAssociations -ExpectedUserSid $sid

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

Set-AtlasTaskbarPins -Browser $browser
if (-not $FromInstall) {
    Set-AtlasFirstLogonPreferences
}
# A recorded choice whose user part fails here, such as a Store app while offline,
# stays recorded and shows in the health check. It must not leave this account's
# setup to run again at every sign-in, or fail an install whose machine work is done.
try { Invoke-AtlasToggleUserReapply }
catch { Write-Warning "Some recorded choices were not applied for this user: $($_.Exception.Message)" }
Set-SearchTaskbarMode

# Apply this after theme setup, which can overwrite registry-only High Contrast
# flags with the session's cached settings. The API preserves the feature itself.
Initialize-AtlasNativeType
[Atlas.Native.HighContrastShortcut]::DisableForCurrentUser()

if ($FromInstall) {
    Set-SetupMarker -Value 2
    Register-StartCategoryRefresh
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
