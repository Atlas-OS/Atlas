#Requires -Version 5.0

<#
	.SYNOPSIS
	Uninstalls or reinstalls Microsoft Edge and its related components. Made by @he3als.

	.Description
	Uninstalls or reinstalls Microsoft Edge and its related components in a non-forceful manner, based upon switches or user choices in a TUI.

	.PARAMETER UninstallEdge
	Uninstalls Edge, leaving the Edge user data.

	.PARAMETER InstallEdge
	Installs Edge, leaving the previous Edge user data.

	.PARAMETER InstallWebView
	Installs Edge WebView2 using the Evergreen installer.

	.PARAMETER RemoveEdgeData
	Removes all Edge user data. Compatible with -InstallEdge.

	.PARAMETER KeepAppX
	Doesn't check for and remove the AppX, in case you want to use alternative AppX removal methods. Doesn't work with UninstallEdge.

	.PARAMETER NonInteractive
	When combined with other parameters, this does not prompt the user for anything.

	.LINK
	https://github.com/he3als/EdgeRemover
#>

param (
    [switch]$UninstallEdge,
    [switch]$InstallEdge,
    [switch]$InstallWebView,
    [switch]$RemoveEdgeData,
    [switch]$KeepAppX,
    [switch]$NonInteractive
)

Set-StrictMode -Version 3.0

$version = '1.9.5'

$ProgressPreference = 'SilentlyContinue'
$sys32 = [Environment]::GetFolderPath('System')
$windir = [Environment]::GetFolderPath('Windows')
$env:path = "$windir;$sys32;$sys32\Wbem;$sys32\WindowsPowerShell\v1.0;" + $env:path
$msedgeExePaths = @(
    "$([Environment]::GetFolderPath('ProgramFilesx86'))\Microsoft\Edge\Application\msedge.exe",
    "$([Environment]::GetFolderPath('ProgramFiles'))\Microsoft\Edge\Application\msedge.exe"
)

if ($NonInteractive -and (!$UninstallEdge -and !$InstallEdge -and !$InstallWebView)) {
    $NonInteractive = $false
}
if ($InstallEdge -and $UninstallEdge) {
    throw "You can't use both -InstallEdge and -UninstallEdge as arguments."
}

function Pause ($message = 'Press Enter to exit') {
    if (!$NonInteractive) { $null = Read-Host $message }
}

enum LogLevel {
    Success
    Info
    Warning
    Error
    Critical
}
function Write-Status {
    param (
        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [string]$Text,
        [LogLevel]$Level = 'Info',
        [switch]$Exit,
        [string]$ExitString = 'Press Enter to exit',
        [int]$ExitCode = 1
    )

    $colour = @(
        'Green',
        'White',
        'Yellow',
        'Red',
        'Red'
    )[$([LogLevel].GetEnumValues().IndexOf($Level))]

    $Text -split "`n" | ForEach-Object {
        Write-Host "[$($Level.ToString().ToUpper())] $_" -ForegroundColor $colour
    }

    if ($Exit) {
        Write-Output ''
        Pause $ExitString
        exit $ExitCode
    }
}

function InternetCheck {
    try {
        Invoke-WebRequest -Uri 'https://www.microsoft.com/robots.txt' -Method GET -TimeoutSec 10 -ErrorAction Stop | Out-Null
    }
    catch {
        Write-Status "Failed to reach Microsoft.com via web request. You must have an internet connection to reinstall Edge and its components.`n$($_.Exception.Message)" -Level Critical -Exit -ExitCode 404
    }
}

function DeleteIfExist($Path) {
    if (Test-Path $Path) {
        Remove-Item -Path $Path -Force -Recurse -Confirm:$false
    }
}

function Remove-EdgePath {
    # Take ownership, grant Administrators full control, then delete - with a cmd 'rd'
    # retry for trees the provider can't remove.
    param([Parameter(Mandatory = $true)][string]$Path)

    if (-not (Test-Path -LiteralPath $Path)) {
        return
    }

    & takeown.exe /F "$Path" /R /D Y *> $null
    & icacls.exe "$Path" /grant '*S-1-5-32-544:(F)' /T /C *> $null
    Remove-Item -LiteralPath $Path -Recurse -Force -ErrorAction SilentlyContinue
    if (Test-Path -LiteralPath $Path) {
        & cmd.exe /c rd /s /q "$Path" *> $null
    }
}

function EdgeInstalled {
    foreach ($msedgeExe in $msedgeExePaths) {
        if (Test-Path $msedgeExe) {
            return $true
        }
    }

    return $false
}

function KillEdgeProcesses {
    $ErrorActionPreference = 'SilentlyContinue'
    foreach ($service in (Get-Service -Name '*edge*' | Where-Object { $_.DisplayName -like '*Microsoft Edge*' }).Name) {
        Stop-Service -Name $service -Force
    }

    # Match only the Edge browser and update infrastructure; a bare '\Microsoft\*' would
    # also kill classic Teams, x86 Office and OneDrive. Trailing '\' stops the 'Edge' glob
    # from also matching '\Microsoft\EdgeWebView'.
    $edgePathPatterns = @()
    foreach ($programFiles in @([Environment]::GetFolderPath('ProgramFilesX86'), [Environment]::GetFolderPath('ProgramFiles'))) {
        foreach ($edgeComponent in @('Edge', 'EdgeUpdate', 'EdgeCore')) {
            $edgePathPatterns += "$programFiles\Microsoft\$edgeComponent\*"
        }
    }

    foreach (
        $process in
        (Get-Process | Where-Object {
            $processPath = $_.Path
            # Never the WebView2 Runtime (by name or install path): the shell hosts it on
            # 24H2/25H2 and we don't uninstall it, so killing it drops the live session.
            $isWebView = ($_.Name -eq 'msedgewebview2') -or ($processPath -like '*\Microsoft\EdgeWebView\*')
            (-not $isWebView) -and (
                (@($edgePathPatterns | Where-Object { $processPath -like $_ }).Count -gt 0) -or
                ($_.Name -match '^(msedge|MicrosoftEdge|edgeupdate)')
            )
        }).Id
    ) {
        Stop-Process -Id $process -Force
    }
    $ErrorActionPreference = 'Continue'
}

function DisableEdgeUpdateInfrastructure {
    $serviceNames = @(
        'edgeupdate',
        'edgeupdatem',
        'MicrosoftEdgeUpdate',
        'MicrosoftEdgeElevationService'
    )

    try {
        $serviceNames += Get-CimInstance Win32_Service -ErrorAction Stop |
        Where-Object {
            ($_.Name -like '*edge*' -and $_.DisplayName -like '*Microsoft Edge*') -or
            ($_.PathName -like '*\Microsoft\EdgeUpdate\*') -or
            ($_.PathName -like '*\Microsoft\Edge\Application\*')
        } |
        Select-Object -ExpandProperty Name
    }
    catch {
        Write-Status "Failed to discover Edge services: $($_.Exception.Message)" -Level Warning
    }

    foreach ($serviceName in @($serviceNames | Where-Object { $_ } | Sort-Object -Unique)) {
        $service = Get-Service -Name $serviceName -ErrorAction SilentlyContinue
        if ($null -eq $service) {
            continue
        }

        try {
            if ($service.Status -ne 'Stopped') {
                Stop-Service -Name $serviceName -Force -ErrorAction SilentlyContinue
            }
            Set-Service -Name $serviceName -StartupType Disabled -ErrorAction Stop
        }
        catch {
            Write-Status "Failed to disable Edge update service '$serviceName': $($_.Exception.Message)" -Level Warning
        }
    }

    # The update tasks can carry a GUID suffix (MicrosoftEdgeUpdateTaskMachineCore{GUID}),
    # so match by prefix - deleting only the bare names leaves orphaned tasks that fail
    # 0x80070002 every run. Remove the on-disk definitions too.
    Get-ScheduledTask -TaskName 'MicrosoftEdge*' -ErrorAction SilentlyContinue |
        Unregister-ScheduledTask -Confirm:$false -ErrorAction SilentlyContinue
    Get-ChildItem -LiteralPath (Join-Path -Path ([Environment]::GetFolderPath('System')) -ChildPath 'Tasks') -Filter 'MicrosoftEdge*' -ErrorAction SilentlyContinue |
        ForEach-Object { Remove-Item -LiteralPath $_.FullName -Force -ErrorAction SilentlyContinue }
}

function Remove-EdgeRegistration {
    # Edge leaves shell registration behind after its binaries are gone: dead protocol
    # handlers (microsoft-edge:), App Paths\msedge.exe, a binary-less Apps-list Uninstall
    # row, StartMenuInternet and EdgeUpdate\Clients. Each key is removed from both the
    # 64- and 32-bit views. WebView2 keys are untouched.
    $edgeKeys = @(
        'HKLM\SOFTWARE\Microsoft\Edge'
        'HKLM\SOFTWARE\Microsoft\EdgeUpdate'
        'HKLM\SOFTWARE\Microsoft\MicrosoftEdge'
        'HKLM\SOFTWARE\Microsoft\Active Setup\Installed Components\{9459C573-B17A-45AE-9F64-1857B5D58CEE}'
        'HKLM\SOFTWARE\Microsoft\Internet Explorer\EdgeIntegration'
        'HKLM\SOFTWARE\Microsoft\Internet Explorer\EdgeDebugActivation'
        'HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Image File Execution Options\MicrosoftEdgeUpdate.exe'
        'HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\App Paths\msedge.exe'
        'HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\Microsoft Edge'
        'HKLM\SOFTWARE\Clients\StartMenuInternet\Microsoft Edge'
        'HKLM\SOFTWARE\Classes\microsoft-edge'
        'HKLM\SOFTWARE\Classes\microsoft-edge-holographic'
        'HKLM\SOFTWARE\Classes\MSEdgeHTM'
        'HKLM\SOFTWARE\Classes\MSEdgeMHT'
        'HKLM\SOFTWARE\Classes\AppID\MicrosoftEdgeUpdate.exe'
        'HKCU\SOFTWARE\Microsoft\Windows\Shell\Associations\UrlAssociations\microsoft-edge'
        'HKCU\SOFTWARE\Classes\microsoft-edge'
        'HKCU\SOFTWARE\Classes\MSEdgeHTM'
    )
    foreach ($edgeKey in $edgeKeys) {
        foreach ($view in @('/reg:64', '/reg:32')) {
            & reg.exe delete "$edgeKey" /f $view *> $null
        }
    }
}

function InstallEdgeChromium {
    InternetCheck

    $temp = mkdir (Join-Path $([System.IO.Path]::GetTempPath()) $(New-Guid))
    $msi = "$temp\edge.msi"
    $msiLog = "$temp\edgeMsi.log"
    $link = 'Undefined'

    if ([Environment]::Is64BitOperatingSystem) {
        $arm = ((Get-CimInstance -Class Win32_ComputerSystem).SystemType -match 'ARM64') -or ($env:PROCESSOR_ARCHITECTURE -eq 'ARM64')
        $archString = ('x64', 'arm64')[$arm]
    }
    else {
        $archString = 'x86'
    }

    Write-Status 'Requesting from the Microsoft Edge Update API...'
    try {
        try {
            $edgeUpdateApi = (Invoke-WebRequest 'https://edgeupdates.microsoft.com/api/products' -UseBasicParsing).Content | ConvertFrom-Json
        }
        catch {
            Write-Status "Failed to request from EdgeUpdate API!
Error: $_" -Level Critical -Exit -ExitCode 4
        }

        $edgeItem = ($edgeUpdateApi | Where-Object { $_.Product -eq 'Stable' }).Releases |
        Where-Object { $_.Platform -eq 'Windows' -and $_.Architecture -eq $archString } |
        Where-Object { $_.Artifacts.Count -ne 0 } | Select-Object -First 1

        if ($null -eq $edgeItem) {
            Write-Status 'Failed to parse EdgeUpdate API! No matching artifacts found.' -Level Critical -Exit
        }

        $hashAlg = $edgeItem.Artifacts.HashAlgorithm | ForEach-Object { if ([string]::IsNullOrEmpty($_)) { 'SHA256' } else { $_ } }
        foreach ($var in @{
                link     = $edgeItem.Artifacts.Location
                hash     = $edgeItem.Artifacts.Hash
                version  = $edgeItem.ProductVersion
                sizeInMb = [math]::round($edgeItem.Artifacts.SizeInBytes / 1Mb)
                released = Get-Date $edgeItem.PublishedTime
            }.GetEnumerator()) {
            $val = $var.Value | Select-Object -First 1
            # Values can be non-strings (e.g. DateTime/double), so avoid .Length under strict mode.
            if ([string]::IsNullOrEmpty([string]$val)) {
                Set-Variable -Name $var.Key -Value 'Undefined'
                if ($var.Key -eq 'link') { throw 'Failed to parse download link!' }
            }
            else {
                Set-Variable -Name $var.Key -Value $val
            }
        }
    }
    catch {
        Write-Status "Failed to parse Microsoft Edge from `"$link`"!
Error: $_" -Level Critical -Exit -ExitCode 5
    }
    Write-Status 'Parsed Microsoft Edge Update API!' -Level Success

    Write-Host "`nDownloading Microsoft Edge:" -ForegroundColor Cyan
    @(
        @('Released on: ', $released),
        @('Version: ', "$version (Stable)"),
        @('Size: ', "$sizeInMb Mb")
    ) | Foreach-Object {
        Write-Host ' - ' -NoNewline -ForegroundColor Magenta
        Write-Host $_[0] -NoNewline -ForegroundColor Yellow
        Write-Host $_[1]
    }

    Write-Output ''
    try {
        if ($null -eq (Get-Command curl.exe -EA 0)) {
            Write-Status "Couldn't find cURL, using Invoke-WebRequest, which is slower..." -Level Warning
            Invoke-WebRequest -Uri $link -OutFile $msi -UseBasicParsing
        }
        else {
            curl.exe -#L "$link" -o "$msi"
        }
    }
    catch {
        Write-Status "Failed to download Microsoft Edge from `"$link`"!
Error: $_" -Level Critical -Exit -ExitCode 6
    }
    Write-Output ''

    if ($hash -eq 'Undefined') {
        Write-Status "Not verifying hash as it's undefined, download might have failed." -Level Warning
    }
    else {
        Write-Status 'Verifying download by checking its hash...'
        if ((Get-FileHash -LiteralPath $msi -Algorithm $hashAlg).Hash -eq $hash) {
            Write-Status 'Verified the Microsoft Edge installer!' -Level Success
        }
        else {
            Write-Status 'Edge installer hash does not match. Refusing to continue with an untrusted installer.' -Level Critical -Exit -ExitCode 10
        }
    }

    Write-Status 'Installing Microsoft Edge...'
    Start-Process -FilePath 'msiexec.exe' -ArgumentList "/i `"$msi`" /l `"$msiLog`" /quiet" -Wait

    Write-Status 'Repairing Microsoft Edge...'
    Start-Process -FilePath 'msiexec.exe' -ArgumentList "/fa `"$msi`" /l `"$msiLog`" /quiet" -Wait

    if (!(Test-Path $msiLog)) {
        Write-Status "Couldn't find installer log at `"$msiLog`"! This likely means it failed." -Level Critical -Exit -ExitCode 7
    }

    Write-Status -Text "Installer log path: `"$msiLog`""
    if (@($(Get-Content $msiLog) -like '*Product: Microsoft Edge -- * completed successfully.*').Count -eq 0) {
        Write-Status "Can't find success string from Edge install log - it seems like the install was a failure." -Level Error -Exit -ExitCode 8
    }

    Write-Status -Text 'Installed Microsoft Edge!' -Level Success
}

function InstallWebView {
    InternetCheck

    $dlPath = "$((Join-Path $([System.IO.Path]::GetTempPath()) $(New-Guid)))-webview2.exe"
    $link = 'https://go.microsoft.com/fwlink/p/?LinkId=2124703'

    Write-Status 'Downloading Edge WebView...'
    try {
        if ($null -eq (Get-Command curl.exe -EA 0)) {
            Write-Status "Couldn't find cURL, using Invoke-WebRequest, which is slower..." -Level Warning
            Invoke-WebRequest -Uri $link -OutFile $dlPath -UseBasicParsing
        }
        else {
            curl.exe -Ls "$link" -o "$dlPath"
        }
    }
    catch {
        Write-Status "Failed to download Edge WebView from `"$link`"!
Error: $_" -Level Critical -Exit -ExitCode 9
    }

    Write-Status 'Installing Edge WebView...'
    Start-Process -FilePath "$dlPath" -ArgumentList '/silent /install' -Wait

    Write-Status 'Installed Edge WebView!' -Level Success
}

# Deliberately self-contained (standalone script); canonical check lives in Atlas.Core\Test-AtlasAdmin.
# Running as TrustedInstaller/SYSTEM breaks parts of the removal
if ([Security.Principal.WindowsIdentity]::GetCurrent().User.Value -eq 'S-1-5-18') {
    Write-Status "This script can't be ran as TrustedInstaller/SYSTEM.
Please relaunch this script under a regular admin account." -Level Critical -Exit
}
else {
    if (!([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltinRole]::Administrator)) {
        if ($PSBoundParameters.Count -le 0 -and !$args) {
            Start-Process cmd "/c PowerShell -NoP -EP RemoteSigned -File `"$PSCommandPath`"" -Verb RunAs
            exit
        }
        else {
            throw 'This script must be run as an administrator.'
        }
    }
}

$edgeInstalled = EdgeInstalled
if (!$UninstallEdge -and !$InstallEdge -and !$InstallWebView) {
    $host.UI.RawUI.WindowTitle = "AtlasOS EdgeRemover"

    $continue = $false
    $RemoveEdgeData = $false
    while (!$continue) {
        Clear-Host
        $description = "This script removes or installs Microsoft Edge."
        Write-Host "$description`n" -ForegroundColor Blue
        Write-Host @"
To select an option, type its number.
To perform an action, also type its number.
"@ -ForegroundColor Yellow

        Write-Host "`nEdge is currently detected as: " -NoNewline -ForegroundColor Green
        Write-Host "$(@("Uninstalled", "Installed")[$edgeInstalled])" -ForegroundColor Cyan

        Write-Host "`n$("-" * $description.Length)" -ForegroundColor Magenta

        Write-Host "`nActions:"
        Write-Host @"
[1] Uninstall Edge
[2] Install Edge
[3] Install WebView
[4] Install both Edge & WebView
"@ -ForegroundColor Cyan

        $userInput = $Host.UI.RawUI.ReadKey('NoEcho,IncludeKeyDown')

        switch ($userInput.VirtualKeyCode) {
            49 {
                # uninstall Edge (1)
                $UninstallEdge = $true
                $continue = $true
            }
            50 {
                # reinstall Edge (2)
                $InstallEdge = $true
                $continue = $true
            }
            51 {
                # reinstall WebView (3)
                $InstallWebView = $true
                $continue = $true
            }
            52 {
                # reinstall both (4)
                $InstallWebView = $true
                $InstallEdge = $true
                $continue = $true
            }
        }
    }

    Clear-Host
}

if ($UninstallEdge) {
    Write-Status 'Uninstalling Edge Chromium...'
    KillEdgeProcesses
    DisableEdgeUpdateInfrastructure

    # Kick off Edge's own uninstaller detached and DO NOT wait for it. A synchronous
    # system-level --force-uninstall runs its RestartManager phase in the live session and
    # signs the user out on 24H2/25H2; launching it detached lets the direct file deletion
    # below finish the removal first.
    foreach ($root in @(
            "$([Environment]::GetFolderPath('ProgramFilesx86'))\Microsoft\Edge\Application",
            "$([Environment]::GetFolderPath('ProgramFiles'))\Microsoft\Edge\Application"
        )) {
        if (-not (Test-Path $root)) {
            continue
        }
        foreach ($setup in @(Get-ChildItem -Path $root -Filter 'setup.exe' -Recurse -ErrorAction SilentlyContinue | Sort-Object -Property FullName -Unique)) {
            Write-Status "Launching uninstaller at '$($setup.FullName)'..."
            Start-Process -FilePath $setup.FullName -ArgumentList '--uninstall --system-level --force-uninstall' -WindowStyle Hidden -ErrorAction SilentlyContinue
        }
    }

    Start-Sleep -Seconds 3
    KillEdgeProcesses

    # Remove the Edge browser install directly. Only the browser and its update
    # infrastructure - never WebView2 (\Microsoft\EdgeWebView), which stays installed.
    foreach ($programFiles in @([Environment]::GetFolderPath('ProgramFilesX86'), [Environment]::GetFolderPath('ProgramFiles'))) {
        foreach ($folder in @('Edge', 'EdgeCore', 'EdgeUpdate')) {
            Remove-EdgePath -Path (Join-Path -Path $programFiles -ChildPath "Microsoft\$folder")
        }
    }
    Get-ChildItem -LiteralPath ([Environment]::GetFolderPath('System')) -Filter 'MicrosoftEdge*.exe' -ErrorAction SilentlyContinue | ForEach-Object {
        & takeown.exe /F "$($_.FullName)" *> $null
        & icacls.exe "$($_.FullName)" /grant '*S-1-5-32-544:(F)' /C *> $null
        Remove-Item -LiteralPath $_.FullName -Force -ErrorAction SilentlyContinue
    }

    # Remove leftover Edge shortcuts (they now point at deleted binaries and fail to open):
    # every user's Desktop, Quick Launch and taskbar pin, plus the Public Desktop and the
    # common Start Menu.
    $edgeShortcutNames = @('edge.lnk', 'Microsoft Edge.lnk')
    $relativeShortcutDirs = @(
        'Desktop'
        'AppData\Roaming\Microsoft\Internet Explorer\Quick Launch'
        'AppData\Roaming\Microsoft\Internet Explorer\Quick Launch\User Pinned\TaskBar'
        'AppData\Roaming\Microsoft\Windows\Start Menu\Programs'
    )
    $profilePaths = @()
    try {
        Get-ChildItem -LiteralPath 'HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\ProfileList' -ErrorAction Stop | ForEach-Object {
            $profilePath = (Get-ItemProperty -LiteralPath $_.PSPath -Name 'ProfileImagePath' -ErrorAction SilentlyContinue).ProfileImagePath
            if ($profilePath) {
                $profilePaths += $profilePath
            }
        }
    }
    catch {
        $null = $_
    }
    $shortcutDirs = @([Environment]::GetFolderPath('CommonDesktopDirectory'), [Environment]::GetFolderPath('CommonPrograms'))
    foreach ($profilePath in $profilePaths) {
        foreach ($relativeShortcutDir in $relativeShortcutDirs) {
            $shortcutDirs += (Join-Path -Path $profilePath -ChildPath $relativeShortcutDir)
        }
    }
    foreach ($shortcutDir in ($shortcutDirs | Select-Object -Unique)) {
        foreach ($edgeShortcutName in $edgeShortcutNames) {
            Remove-Item -LiteralPath (Join-Path -Path $shortcutDir -ChildPath $edgeShortcutName) -Force -ErrorAction SilentlyContinue
        }
    }

    # Drop the now-dangling Edge shell registration (protocol handlers, App Paths,
    # Apps-list Uninstall row, StartMenuInternet, EdgeUpdate clients).
    Remove-EdgeRegistration

    if (EdgeInstalled) {
        Write-Status 'Edge binaries were not fully removed. Continuing so playbook cleanup can finish.' -Level Warning
    }
    else {
        Write-Status 'Successfully removed Microsoft Edge.' -Level Success
    }

    Write-Output ""
}

if ($RemoveEdgeData) {
    KillEdgeProcesses
    DeleteIfExist "$([Environment]::GetFolderPath('LocalApplicationData'))\Microsoft\Edge"
    Write-Status 'Removed any existing Edge Chromium user data.'
    Write-Output ''
}

if ($InstallEdge) {
    InstallEdgeChromium
    Write-Output ''
}
if ($InstallWebView) {
    InstallWebView
    Write-Output ''
}

Write-Host 'Completed.' -ForegroundColor Cyan
if ($NonInteractive) { exit }
Pause
