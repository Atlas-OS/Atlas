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

$ProgressPreference = "SilentlyContinue"
$sys32 = [Environment]::GetFolderPath('System')
$env:path = "$([Environment]::GetFolderPath('Windows'));$sys32;$sys32\Wbem;$sys32\WindowsPowerShell\v1.0;" + $env:path

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
		[Parameter(Mandatory=$true)]
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
	)[$([LogLevel].GetEnumValues().IndexOf([LogLevel]"$Level"))]

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
		Write-Status "Failed to ping Microsoft! You must have an internet connection to reinstall Edge and its components." -Level Critical -Exit
	}
}

function DeleteIfExist($Path) {
	if (Test-Path $Path) {
		Remove-Item -Path $Path -Force -Recurse -Confirm:$false
	}
}

function Uninstall-MsiexecAppByName {
	param(
		[Parameter(Mandatory = $true)]
		[ValidateNotNullOrEmpty()]
		[string]$Name
	)

	$uninstallKeyPath = "Microsoft\Windows\CurrentVersion\Uninstall"
	$uninstallKeys = (Get-ChildItem -Path @(
		"HKLM:\SOFTWARE\$uninstallKeyPath",
		"HKLM:\SOFTWARE\WOW6432Node\$uninstallKeyPath",
		"HKCU:\SOFTWARE\$uninstallKeyPath",
		"HKCU:\SOFTWARE\WOW6432Node\$uninstallKeyPath"
	) -EA SilentlyContinue) -match "\{\b[A-Fa-f0-9]{8}(?:-[A-Fa-f0-9]{4}){3}-[A-Fa-f0-9]{12}\b\}"

	foreach ($key in $uninstallKeys.PSPath) {
		if (((Get-ItemProperty -Path $key).DisplayName -like "*$Name*") -and ((Get-ItemProperty -Path $key).UninstallString -like "*MsiExec.exe*")) {
			Write-Status "Uninstalling `"$name`" using Windows Installer..."
			Start-Process -FilePath "msiexec.exe" -ArgumentList "/qn /X$(Split-Path -Path $key -Leaf) REBOOT=ReallySuppress /norestart" -Wait | Out-Null
		}
	}
}

function KillEdgeProcesses {
	$ErrorActionPreference = 'SilentlyContinue'
	foreach ($service in (Get-Service -Name "*edge*" | Where-Object {$_.DisplayName -like "*Microsoft Edge*"}).Name) {
		Stop-Service -Name $service -Force
	}
	foreach (
		$process in
		(Get-Process | Where-Object {($_.Path -like "$([Environment]::GetFolderPath('ProgramFilesX86'))\Microsoft\*") -or ($_.Name -like "*msedge*")}).Id
	) {
		Stop-Process -Id $process -Force
	}
	$ErrorActionPreference = 'Continue'	
}

function RemoveEdgeChromium {
	$baseKey = "HKLM:\SOFTWARE\WOW6432Node\Microsoft"
	
	Write-Status "Terminating Microsoft Edge processes..."
	KillEdgeProcesses

	# check if 'experiment_control_labels' value exists and delete it if found
	$keyPath = Join-Path -Path $baseKey -ChildPath "EdgeUpdate\ClientState\{56EB18F8-B008-4CBD-B6D2-8C97FE7E9062}"
	$valueName = "experiment_control_labels"
	if (Test-Path $keyPath) {
		if ($null -ne (Get-ItemProperty -Path $keyPath -Name $valueName -ErrorAction 0)) {
			Remove-ItemProperty -Path $keyPath -Name $valueName -Force | Out-Null
		}
	}

	# allow Edge uninstall
	# seems to no longer exist, kept anyways for legacy purposes
	# replaced with modifying IntegratedServicesRegionPolicySet.json
	$devKeyPath = Join-Path -Path $baseKey -ChildPath "EdgeUpdateDev"
	if (!(Test-Path $devKeyPath)) { New-Item -Path $devKeyPath -ItemType "Key" -Force | Out-Null }
	Set-ItemProperty -Path $devKeyPath -Name "AllowUninstall" -Value "" -Type String -Force | Out-Null

	# modifies IntegratedServicesRegionPolicySet as that's now checked for Edge uninstall
	# likely to be the most future proof method, although i'm not sure what could happen next
	$integratedServicesPath = "$sys32\IntegratedServicesRegionPolicySet.json"
	if (!(Test-Path $integratedServicesPath)) {
		Write-Warning "'$integratedServicesPath' not found, uninstall might fail."
	} else {
		try {
			$admin = [System.Security.Principal.NTAccount]$(New-Object System.Security.Principal.SecurityIdentifier('S-1-5-32-544')).Translate([System.Security.Principal.NTAccount]).Value

			# get perms (normally TrustedInstaller only)
			$acl = Get-Acl -Path $integratedServicesPath
			$backup = [System.Security.AccessControl.FileSecurity]::new()
			$backup.SetSecurityDescriptorSddlForm($acl.Sddl)
			# full control
			$acl.SetOwner($admin)
			$rule = New-Object System.Security.AccessControl.FileSystemAccessRule($admin, "FullControl", "Allow")
			$acl.AddAccessRule($rule)
			# set modified ACL
			Set-Acl -Path $integratedServicesPath -AclObject $acl

			# modify the stuff
			$integratedServices = Get-Content $integratedServicesPath | ConvertFrom-Json
			($integratedServices.policies | Where-Object { ($_.'$comment' -like "*Edge*") -and ($_.'$comment' -like "*uninstall*") }).defaultState = 'enabled'
			$modifiedJson = $integratedServices | ConvertTo-Json -Depth 100

			$backupIntegratedServicesName = "IntegratedServicesRegionPolicySet.json.$([System.IO.Path]::GetRandomFileName())"
			Rename-Item $integratedServicesPath -NewName $backupIntegratedServicesName -Force
			Set-Content $integratedServicesPath -Value $modifiedJson -Force -Encoding UTF8	
		} catch {
			Write-Error "Failed to modify region policies. $_"
		}	
	}

	# uninstall Edge with MsiExec (e.g. WinGet installs)
	# has to be done before uninstalling with CLI args
	Uninstall-MsiexecAppByName -Name "Microsoft Edge"

	# uninstall Edge
	$uninstallKeyPath = Join-Path -Path $baseKey -ChildPath "Windows\CurrentVersion\Uninstall\Microsoft Edge"
	if (Test-Path $uninstallKeyPath) {
		$uninstallString = (Get-ItemProperty -Path $uninstallKeyPath).UninstallString + " --force-uninstall"
		Start-Process -Wait cmd.exe -ArgumentList "/c start /wait `"`" $uninstallString" -WindowStyle Hidden
	} else {
		$edges = @(); 'LocalApplicationData','ProgramFilesX86','ProgramFiles' | ForEach-Object {
			$folder = [Environment]::GetFolderPath($_)
			$edges += Get-ChildItem "$folder\Microsoft\Edge*\setup.exe" -Recurse -EA SilentlyContinue | Where-Object {($_ -like '*Edge\Application*') -or ($_ -like '*SxS\Application*')}
		}
		foreach ($setup in $edges) {
			$sulevel = ('--system-level','--user-level')[$setup -like '*\AppData\Local\*']
			Start-Process -Wait $setup -ArgumentList "--uninstall --msedge $sulevel --channel=stable --verbose-logging --force-uninstall"
		}
	}

	# revert IntegratedServicesRegionPolicySet modification
	if ($backupIntegratedServicesName) {
		Remove-Item $integratedServicesPath -Force
		Rename-Item "$sys32\$backupIntegratedServicesName" -NewName $integratedServicesPath -Force
		Set-Acl -Path $integratedServicesPath -AclObject $backup
	}

	# remove old shortcuts
	"$([Environment]::GetFolderPath('Desktop'))\Microsoft Edge.lnk",
	"$([Environment]::GetFolderPath('CommonStartMenu'))\Microsoft Edge.lnk" | ForEach-Object { DeleteIfExist $_ }

	# restart explorer if Copilot is enabled - this will hide the Copilot button
	if ((Get-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" -Name "ShowCopilotButton" -EA 0)."ShowCopilotButton" -eq 1) {
		Stop-Process -Name explorer -Force -ErrorAction SilentlyContinue
	}
}

function RemoveEdgeAppX {
	# i'm aware of how this is deprecated
	# kept for legacy purposes just in case someone's using an older build of Windows
	# will be removed eventually

	$SID = (New-Object System.Security.Principal.NTAccount([Environment]::UserName)).Translate([Security.Principal.SecurityIdentifier]).Value

	# remove from Registry
	$appxStore = '\SOFTWARE\Microsoft\Windows\CurrentVersion\Appx\AppxAllUserStore'
	$pattern = "HKLM:$appxStore\InboxApplications\Microsoft.MicrosoftEdge_*_neutral__8wekyb3d8bbwe"
	$edgeAppXKey = (Get-Item -Path $pattern).PSChildName
	if (Test-Path "$pattern") { reg delete "HKLM$appxStore\InboxApplications\$edgeAppXKey" /f | Out-Null }

	# make the Edge AppX able to uninstall and uninstall
	New-Item -Path "HKLM:$appxStore\EndOfLife\$SID\Microsoft.MicrosoftEdge_8wekyb3d8bbwe" -Force | Out-Null
	Get-AppxPackage -Name Microsoft.MicrosoftEdge | Remove-AppxPackage | Out-Null
	Remove-Item -Path "HKLM:$appxStore\EndOfLife\$SID\Microsoft.MicrosoftEdge_8wekyb3d8bbwe" -Force | Out-Null
}


function InstallEdgeChromium {
	InternetCheck

	$temp = mkdir (Join-Path $([System.IO.Path]::GetTempPath()) $(New-Guid))
	$msi = "$temp\edge.msi"
	$msiLog = "$temp\edgeMsi.log"
	
	if ([Environment]::Is64BitOperatingSystem) {
		$arm = ((Get-CimInstance -Class Win32_ComputerSystem).SystemType -match 'ARM64') -or ($env:PROCESSOR_ARCHITECTURE -eq 'ARM64')
		$archString = ('x64', 'arm64')[$arm]
	} else {
		$archString = 'x86'
	}
	
	Write-Status "Requesting from the Microsoft Edge Update API..."
	try {
		try {
			$edgeUpdateApi = (Invoke-WebRequest "https://edgeupdates.microsoft.com/api/products" -UseBasicParsing).Content | ConvertFrom-Json
		} catch {
			Write-Status "Failed to request from EdgeUpdate API!
Error: $_" -Level Critical -Exit
		}

		$edgeItem = ($edgeUpdateApi | ? { $_.Product -eq 'Stable' }).Releases |
			Where-Object { $_.Platform -eq 'Windows' -and $_.Architecture -eq $archString } |
			Where-Object { $_.Artifacts.Count -ne 0 } | Select-Object -First 1
		
		if ($null -eq $edgeItem) {
			Write-Status "Failed to parse EdgeUpdate API! No matching artifacts found." -Level Critical -Exit
		}

		$hashAlg = $edgeItem.Artifacts.HashAlgorithm | % { if ([string]::IsNullOrEmpty($_)) { "SHA256" } else { $_ } }
		foreach ($var in @{
			link = $edgeItem.Artifacts.Location
			hash = $edgeItem.Artifacts.Hash
			version = $edgeItem.ProductVersion
			sizeInMb = [math]::round($edgeItem.Artifacts.SizeInBytes/1Mb)
			released = Get-Date $edgeItem.PublishedTime
		}.GetEnumerator()) {
			$val = $var.Value | Select-Object -First 1
			if ($val.Length -le 0) {
				Set-Variable -Name $var.Key -Value "Undefined"
				if ($var.Key -eq 'link') { throw "Failed to parse download link!" }
			} else {
				Set-Variable -Name $var.Key -Value $val
			}
		}
	} catch {
		Write-Status "Failed to parse Microsoft Edge from `"$link`"!
Error: $_" -Level Critical -Exit
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
		} else {
			curl.exe -#L "$link" -o "$msi"
		}
	} catch {
		Write-Status "Failed to download Microsoft Edge from `"$link`"!
Error: $_" -Level Critical -Exit
	}
	Write-Output ""
	
	if ($hash -eq "Undefined") {
		Write-Status "Not verifying hash as it's undefined, download might have failed." -Level Warning
	} else {
		Write-Status "Verifying download by checking its hash..."
		if ((Get-FileHash -LiteralPath $msi -Algorithm $hashAlg).Hash -eq $hash) {
			Write-Status "Verified the Microsoft Edge installer!" -Level Success
		} else {
			Write-Status "Edge installer hash does not match. The installer might be corrupted. Continuing anyways..." -Level Error
		}
	}
	
	Write-Status "Installing Microsoft Edge..."
	Start-Process -FilePath "msiexec.exe" -ArgumentList "/i `"$msi`" /l `"$msiLog`" /quiet" -Wait
	
	if (!(Test-Path $msiLog)) {
		Write-Status "Couldn't find installer log at `"$msiLog`"! This likely means it failed." -Level Critical -Exit
	}
	
	Write-Status -Text "Installer log path: `"$msiLog`""
	if ($null -eq ($(Get-Content $msiLog) -like "*Product: Microsoft Edge -- * completed successfully.*")) {
		Write-Status "Can't find sucess string from Edge install log - it seems like the install was a failure." -Level Error -Exit
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
		} else {
			curl.exe -Ls "$link" -o "$dlPath"
		}
	} catch {
		Write-Status "Failed to download Edge WebView from `"$link`"!
Error: $_" -Level Critical -Exit
	}

	Write-Status "Installing Edge WebView..."
	Start-Process -FilePath "$dlPath" -ArgumentList "/silent /install" -Wait

	Write-Status "Installed Edge WebView!" -Level Success
}

# SYSTEM check - using SYSTEM previously caused issues
if ([Security.Principal.WindowsIdentity]::GetCurrent().User.Value -eq 'S-1-5-18') {
	Write-Status "This script can't be ran as TrustedInstaller/SYSTEM.
Please relaunch this script under a regular admin account." -Level Critical -Exit
} else {
	if (!([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltinRole]::Administrator)) {
		if ($PSBoundParameters.Count -le 0 -and !$args) {
				Start-Process cmd "/c PowerShell -NoP -EP Bypass -File `"$PSCommandPath`"" -Verb RunAs
				exit
		} else {
			throw "This script must be run as an administrator."
		}
	}
}

# main menu
if (!$UninstallEdge -and !$InstallEdge -and !$InstallWebView) {
	$version = '1.9.2'
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

		Write-Host "`n$("-" * $description.Length)" -ForegroundColor Magenta

		if ($RemoveEdgeData) {$colourData = "Green"; $textData = "Selected"} else {$colourData = "Red"; $textData = "Unselected"}

		Write-Host "`nOptions:"
		Write-Host "[1] Remove Edge User Data ($textData)" -ForegroundColor $colourData
		
		Write-Host "`nActions:"
		Write-Host @"
[2] Uninstall Edge
[3] Install Edge
[4] Install WebView
[5] Install both Edge & WebView
"@ -ForegroundColor Cyan

		$userInput = $Host.UI.RawUI.ReadKey('NoEcho,IncludeKeyDown')

		switch ($userInput.VirtualKeyCode) {
			49 { # remove Edge user data (1)
				$RemoveEdgeData = !$RemoveEdgeData
			}
			50 { # uninstall Edge (2)
				$UninstallEdge = $true
				$continue = $true
			}
			51 { # reinstall Edge (3)
				$InstallEdge = $true
				$continue = $true
			}
			52 { # reinstall WebView (4)
				$InstallWebView = $true
				$continue = $true
			}
			53 { # reinstall both (5)
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
	RemoveEdgeChromium
	if ($null -ne (Get-AppxPackage -Name Microsoft.MicrosoftEdge)) {
		if ($KeepAppX) {
			Write-Status "AppX Edge is being left, there might be a stub..." -Level Warning
		} else {
			Write-Status "Uninstalling AppX Edge..." -Level Warning
			RemoveEdgeAppx
		}
	}
	Write-Output ""
}

if ($RemoveEdgeData) {
	KillEdgeProcesses
	DeleteIfExist "$([Environment]::GetFolderPath('LocalApplicationData'))\Microsoft\Edge"
	Write-Status "Removed any existing Edge Chromium user data." -Level Success
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