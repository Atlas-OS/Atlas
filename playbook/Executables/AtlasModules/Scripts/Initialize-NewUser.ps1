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
try {
    $transcriptDir = Join-Path $env:LOCALAPPDATA 'AtlasOS\Logs'
    $null = New-Item -Path $transcriptDir -ItemType Directory -Force
    $transcriptName = '{0:yyyyMMdd-HHmmss}-new-user-setup-{1}.log' -f (Get-Date), $PID
    Start-Transcript -Path (Join-Path $transcriptDir $transcriptName) | Out-Null
}
catch {
    $null = $_
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

    $policyPath = 'HKCU:\SOFTWARE\Policies\Microsoft\Windows\Explorer'
    try {
        if (-not (Test-Path -LiteralPath $policyPath)) {
            $null = New-Item -Path $policyPath -Force
        }
        Set-ItemProperty -Path $policyPath -Name DisableSearchBoxSuggestions -Value 1 -Type DWord -Force
    }
    catch {
        Write-Warning "Couldn't write optional search policy '$policyPath': $($_.Exception.Message)"
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
    $vbsPath = Join-Path ([Environment]::GetFolderPath('Windows')) `
        'AtlasModules\Scripts\Invoke-InitializeNewUserHidden.vbs'
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
    $runOnceCommand = '"%windir%\System32\wscript.exe" "%windir%\AtlasModules\Scripts\Invoke-InitializeNewUserHidden.vbs"'
    Set-ItemProperty -Path $runOncePath -Name RunScript -Value $runOnceCommand -Type ExpandString -Force
}

$windir = [Environment]::GetFolderPath('Windows')
$atlasModules = Join-Path $windir 'AtlasModules'
$atlasDesktop = Join-Path $windir 'AtlasDesktop'
$initializer = Join-Path $atlasModules 'initPowerShell.ps1'
if (-not (Test-Path -LiteralPath $atlasModules -PathType Container) -or
    -not (Test-Path -LiteralPath $atlasDesktop -PathType Container) -or
    -not (Test-Path -LiteralPath $initializer -PathType Leaf)) {
    throw 'Atlas user-setup files are missing from the Windows directory.'
}
& $initializer

function Invoke-AtlasDesktopCommand {
    param([Parameter(Mandatory)][string]$RelativePath)

    $path = Join-Path $atlasDesktop $RelativePath
    if (-not (Test-Path -LiteralPath $path -PathType Leaf)) {
        throw "Atlas desktop command '$path' was not found."
    }

    & $path /silent
    if ($LASTEXITCODE -ne 0) {
        throw "Atlas desktop command '$path' exited with code $LASTEXITCODE."
    }
}

if (-not $FromInstall) {
    try {
        & (Join-Path $atlasModules 'Scripts\Internal\Initialize-AtlasLibreWolfUser.ps1') `
            -ExpectedUserSid $sid
    }
    catch {
        Write-Warning "Failed to initialize LibreWolf for the current user: $($_.Exception.Message)"
    }

    & (Join-Path $atlasModules 'Scripts\Internal\Set-FileAssociations.ps1') `
        -AssociationProfile Base -ExpectedUserSid $sid
}

if ($setupMarker -lt 1) {
    if (-not $FromInstall) {
        try {
            & (Join-Path $atlasModules 'Scripts\Internal\Show-AtlasToast.ps1') `
                -Title Atlas `
                -Message "Finishing account setup - you'll be signed out for a moment, then it's ready to use."
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

                    if (-not ('Atlas.Wallpaper' -as [type])) {
                        Add-Type -Namespace Atlas -Name Wallpaper -MemberDefinition @'
[System.Runtime.InteropServices.DllImport("user32.dll", CharSet = System.Runtime.InteropServices.CharSet.Auto, SetLastError = true)]
public static extern bool SystemParametersInfo(uint uiAction, uint uiParam, string pvParam, uint fWinIni);
'@
                    }
                    [Atlas.Wallpaper]::SystemParametersInfo(0x14, 0, $wallpaper, 0x03) | Out-Null
                }
            }
            catch {
                Write-Warning "Failed to set the Atlas wallpaper: $($_.Exception.Message)"
            }

            try {
                & (Join-Path $atlasModules 'Scripts\Tasks\Add-MusicVideosToHome.ps1')
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
            & (Join-Path $atlasModules 'Scripts\Tasks\Disable-StoreSearchRecommendations.ps1')
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
    CurrentUserOnly = $true
    NoExplorerStop  = $true
}
if (-not [string]::IsNullOrWhiteSpace($browser)) {
    $pinArguments['Browser'] = $browser
}
& (Join-Path $atlasModules 'Scripts\Internal\Set-TaskbarPins.ps1') @pinArguments
Set-SearchTaskbarMode

if ($FromInstall) {
    Set-SetupMarker -Value 2
    return
}

if ($setupMarker -lt 1) {
    Set-SetupMarker -Value 1
    Start-Sleep -Seconds 5
    & (Join-Path ([Environment]::SystemDirectory) 'logoff.exe')
    if ($LASTEXITCODE -ne 0) {
        throw "logoff.exe exited with code $LASTEXITCODE."
    }
    return
}

Invoke-CurrentSessionExplorerRefresh
Start-Sleep -Seconds 3
Set-SearchTaskbarMode
Set-SetupMarker -Value 2
try {
    Remove-ItemProperty -Path $runOncePath -Name RunScript
}
catch {
    Write-Warning "Failed to remove the completed setup RunOnce value: $($_.Exception.Message)"
}
Start-DelayedSearchFinalizer

try {
    & (Join-Path $atlasModules 'Scripts\Internal\Show-AtlasToast.ps1') `
        -Title Atlas -Message 'Your account is ready to use.'
}
catch {
    Write-Warning "Failed to show the completion toast: $($_.Exception.Message)"
}
