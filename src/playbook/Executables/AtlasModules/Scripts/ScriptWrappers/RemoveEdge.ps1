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

$version = '1.9.4'

$ProgressPreference = "SilentlyContinue"
$sys32 = [Environment]::GetFolderPath('System')
$windir = [Environment]::GetFolderPath('Windows')
$env:path = "$windir;$sys32;$sys32\Wbem;$sys32\WindowsPowerShell\v1.0;" + $env:path
$baseKey = "HKLM:\SOFTWARE" + $(if ([Environment]::Is64BitOperatingSystem) { "\WOW6432Node" }) + "\Microsoft"
$msedgeExe = "$([Environment]::GetFolderPath('ProgramFilesx86'))\Microsoft\Edge\Application\msedge.exe"
$edgeUWP = "$windir\SystemApps\Microsoft.MicrosoftEdge_8wekyb3d8bbwe"

if ($NonInteractive -and (!$UninstallEdge -and !$InstallEdge -and !$InstallWebView)) {
    $NonInteractive = $false
}
if ($InstallEdge -and $UninstallEdge) {
    throw "You can't use both -InstallEdge and -UninstallEdge as arguments."
}

function Pause ($message = "Press Enter to exit") {
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
        [LogLevel]$Level = "Info",
        [switch]$Exit,
        [string]$ExitString = "Press Enter to exit",
        [int]$ExitCode = 1
    )

    $colour = @(
        "Green",
        "White",
        "Yellow",
        "Red",
        "Red"
    )[$([LogLevel].GetEnumValues().IndexOf($Level))]

    $Text -split "`n" | ForEach-Object {
        Write-Host "[$($Level.ToString().ToUpper())] $_" -ForegroundColor $colour
    }

    if ($Exit) {
        Write-Output ""
        Pause $ExitString
        exit $ExitCode
    }
}

function InternetCheck {
    if ($(Test-Connection "microsoft.com" -Count 1 -EA 0; $?) -eq $false) {
        Write-Status "Failed to ping Microsoft! You must have an internet connection to reinstall Edge and its components." -Level Critical -Exit -ExitCode 404
    }
}

function DeleteIfExist($Path) {
    if (Test-Path $Path) {
        Remove-Item -Path $Path -Force -Recurse -Confirm:$false
    }
}

# True if it's installed
function EdgeInstalled {
    Test-Path $msedgeExe
}

function KillEdgeProcesses {
    $ErrorActionPreference = 'SilentlyContinue'
    foreach ($service in (Get-Service -Name "*edge*" | Where-Object { $_.DisplayName -like "*Microsoft Edge*" }).Name) {
        Stop-Service -Name $service -Force
    }
    foreach (
        $process in
        (Get-Process | Where-Object { ($_.Path -like "$([Environment]::GetFolderPath('ProgramFilesX86'))\Microsoft\*") -or ($_.Name -like "*msedge*") }).Id
    ) {
        Stop-Process -Id $process -Force
    }
    $ErrorActionPreference = 'Continue'
}
# things that should always be done before uninstall
function GlobalRemoveMethods {
    Write-Status "Using method $method..." -Level Warning

    # delete experiment_control_labels for key that prevents (or prevented) uninstall
    Remove-ItemProperty -Path "$baseKey\EdgeUpdate\ClientState\{56EB18F8-B008-4CBD-B6D2-8C97FE7E9062}" -Name 'experiment_control_labels' -Force -EA 0

    # allow Edge uninstall
    $devKeyPath = "$baseKey\EdgeUpdateDev"
    if (!(Test-Path $devKeyPath)) { New-Item -Path $devKeyPath -ItemType "Key" -Force | Out-Null }
    Set-ItemProperty -Path $devKeyPath -Name "AllowUninstall" -Value "" -Type String -Force

    Write-Status "Terminating Microsoft Edge processes..."
    KillEdgeProcesses
}


function InstallEdgeChromium {
    InternetCheck

    $temp = mkdir (Join-Path $([System.IO.Path]::GetTempPath()) $(New-Guid))
    $msi = "$temp\edge.msi"
    $msiLog = "$temp\edgeMsi.log"

    if ([Environment]::Is64BitOperatingSystem) {
        $arm = ((Get-CimInstance -Class Win32_ComputerSystem).SystemType -match 'ARM64') -or ($env:PROCESSOR_ARCHITECTURE -eq 'ARM64')
        $archString = ('x64', 'arm64')[$arm]
    }
    else {
        $archString = 'x86'
    }

    Write-Status "Requesting from the Microsoft Edge Update API..."
    try {
        try {
            $edgeUpdateApi = (Invoke-WebRequest "https://edgeupdates.microsoft.com/api/products" -UseBasicParsing).Content | ConvertFrom-Json
        }
        catch {
            Write-Status "Failed to request from EdgeUpdate API!
Error: $_" -Level Critical -Exit -ExitCode 4
        }

        $edgeItem = ($edgeUpdateApi | ? { $_.Product -eq 'Stable' }).Releases |
        Where-Object { $_.Platform -eq 'Windows' -and $_.Architecture -eq $archString } |
        Where-Object { $_.Artifacts.Count -ne 0 } | Select-Object -First 1

        if ($null -eq $edgeItem) {
            Write-Status "Failed to parse EdgeUpdate API! No matching artifacts found." -Level Critical -Exit
        }

        $hashAlg = $edgeItem.Artifacts.HashAlgorithm | % { if ([string]::IsNullOrEmpty($_)) { "SHA256" } else { $_ } }
        foreach ($var in @{
                link     = $edgeItem.Artifacts.Location
                hash     = $edgeItem.Artifacts.Hash
                version  = $edgeItem.ProductVersion
                sizeInMb = [math]::round($edgeItem.Artifacts.SizeInBytes / 1Mb)
                released = Get-Date $edgeItem.PublishedTime
            }.GetEnumerator()) {
            $val = $var.Value | Select-Object -First 1
            if ($val.Length -le 0) {
                Set-Variable -Name $var.Key -Value "Undefined"
                if ($var.Key -eq 'link') { throw "Failed to parse download link!" }
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
    Write-Status "Parsed Microsoft Edge Update API!" -Level Success

    Write-Host "`nDownloading Microsoft Edge:" -ForegroundColor Cyan
    @(
        @("Released on: ", $released),
        @("Version: ", "$version (Stable)"),
        @("Size: ", "$sizeInMb Mb")
    ) | Foreach-Object {
        Write-Host " - " -NoNewline -ForegroundColor Magenta
        Write-Host $_[0] -NoNewline -ForegroundColor Yellow
        Write-Host $_[1]
    }

    Write-Output ""
    try {
        if ($null -eq (Get-Command curl.exe -EA 0)) {
            Write-Status "Couldn't find cURL, using Invoke-WebRequest, which is slower..." -Level Warning
            Invoke-WebRequest -Uri $link -Output $msi -UseBasicParsing
        }
        else {
            curl.exe -#L "$link" -o "$msi"
        }
    }
    catch {
        Write-Status "Failed to download Microsoft Edge from `"$link`"!
Error: $_" -Level Critical -Exit -ExitCode 6
    }
    Write-Output ""

    if ($hash -eq "Undefined") {
        Write-Status "Not verifying hash as it's undefined, download might have failed." -Level Warning
    }
    else {
        Write-Status "Verifying download by checking its hash..."
        if ((Get-FileHash -LiteralPath $msi -Algorithm $hashAlg).Hash -eq $hash) {
            Write-Status "Verified the Microsoft Edge installer!" -Level Success
        }
        else {
            Write-Status "Edge installer hash does not match. The installer might be corrupted. Continuing anyways..." -Level Error
        }
    }

    Write-Status "Installing Microsoft Edge..."
    Start-Process -FilePath "msiexec.exe" -ArgumentList "/i `"$msi`" /l `"$msiLog`" /quiet" -Wait

    if (!(Test-Path $msiLog)) {
        Write-Status "Couldn't find installer log at `"$msiLog`"! This likely means it failed." -Level Critical -Exit -ExitCode 7
    }

    Write-Status -Text "Installer log path: `"$msiLog`""
    if ($null -eq ($(Get-Content $msiLog) -like "*Product: Microsoft Edge -- * completed successfully.*")) {
        Write-Status "Can't find success string from Edge install log - it seems like the install was a failure." -Level Error -Exit -ExitCode 8
    }

    Write-Status -Text "Installed Microsoft Edge!" -Level Success
}

function InstallWebView {
    InternetCheck

    $dlPath = "$((Join-Path $([System.IO.Path]::GetTempPath()) $(New-Guid)))-webview2.exe"
    $link = "https://go.microsoft.com/fwlink/p/?LinkId=2124703"

    Write-Status "Downloading Edge WebView..."
    try {
        if ($null -eq (Get-Command curl.exe -EA 0)) {
            Write-Status "Couldn't find cURL, using Invoke-WebRequest, which is slower..." -Level Warning
            Invoke-WebRequest -Uri $link -Output $dlPath -UseBasicParsing
        }
        else {
            curl.exe -Ls "$link" -o "$dlPath"
        }
    }
    catch {
        Write-Status "Failed to download Edge WebView from `"$link`"!
Error: $_" -Level Critical -Exit -ExitCode 9
    }

    Write-Status "Installing Edge WebView..."
    Start-Process -FilePath "$dlPath" -ArgumentList "/silent /install" -Wait

    Write-Status "Installed Edge WebView!" -Level Success
}

# SYSTEM check - using SYSTEM previously caused issues
if ([Security.Principal.WindowsIdentity]::GetCurrent().User.Value -eq 'S-1-5-18') {
    Write-Status "This script can't be ran as TrustedInstaller/SYSTEM.
Please relaunch this script under a regular admin account." -Level Critical -Exit
}
else {
    if (!([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltinRole]::Administrator)) {
        if ($PSBoundParameters.Count -le 0 -and !$args) {
            Start-Process cmd "/c PowerShell -NoP -EP Bypass -File `"$PSCommandPath`"" -Verb RunAs
            exit
        }
        else {
            throw "This script must be run as an administrator."
        }
    }
}

# main menu
$edgeInstalled = EdgeInstalled
if (!$UninstallEdge -and !$InstallEdge -and !$InstallWebView) {
    $host.UI.RawUI.WindowTitle = "EdgeRemover $version | made by @he3als"

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
    Write-Status "Uninstalling Edge Chromium..."
    try {
        $tempDirectory = Join-Path ([IO.Path]::GetTempPath()) ([IO.Path]::GetRandomFileName())
        New-Item -ItemType Directory -Path $tempDirectory | Out-Null

        & curl.exe -LSs "https://github.com/ShadowWhisperer/Remove-MS-Edge/releases/latest/download/Remove-Edge.exe" -o "$tempDirectory\RemoveEdge.exe"
        if (!$?) {
            Write-Error "Downloading script failed."
            exit 1
        }

        Start-Process -FilePath "$tempDirectory\RemoveEdge.exe" -WindowStyle Hidden -Wait

        exit
    }
    catch {
        Write-Warning "An error occurred: $_"
        return $false
    }
    Write-Output ""
}

if ($InstallEdge) {
    InstallEdgeChromium
    Write-Output ""
}
if ($InstallWebView) {
    InstallWebView
    Write-Output ""
}

Write-Host "Completed." -ForegroundColor Cyan
if ($NonInteractive) { exit }
Pause
