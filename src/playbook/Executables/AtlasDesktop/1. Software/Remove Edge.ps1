[CmdletBinding()]
param (
	[Switch]$UninstallAll,
	[Switch]$AMEWizard
)

$ProgressPreference = "SilentlyContinue"
$user = $env:USERNAME
$SID = (New-Object System.Security.Principal.NTAccount($user)).Translate([Security.Principal.SecurityIdentifier]).Value

if ($Exit -and (-not $UninstallAll)) {
    $Exit = $false
}

function PauseNul ($message = "Press any key to continue... ") {
	Write-Host $message -NoNewLine
	$Host.UI.RawUI.ReadKey('NoEcho,IncludeKeyDown') | Out-Null
}

function DeleteEdgeUpdate {
	# surpress errors as some Edge Update components may not exist
	$global:ErrorActionPreference = 'SilentlyContinue'

	# disable automatic installation of Edge-related applications
	$edgeupdatePath = "HKLM:\SOFTWARE\Policies\Microsoft\EdgeUpdate" | Out-Null
	New-Item -Path $edgeupdatePath -Force | Out-Null
	New-ItemProperty -Path "$edgeupdatePath" -Name "DoNotUpdateToEdgeWithChromium" -Type DWORD -Value 1 | Out-Null
	New-ItemProperty -Path "$edgeupdatePath" -Name "Install{F3017226-FE2A-4295-8BDF-00C3A9A7E4C5}" -Type DWORD -Value 0 | Out-Null
	New-ItemProperty -Path "$edgeupdatePath" -Name "InstallDefault" -Type DWORD -Value 0 | Out-Null

	# remove scheduled tasks
	Stop-Process -Name "MicrosoftEdgeUpdate" -Force | Out-Null
	Remove-Item -Path "HKLM:\SOFTWARE\Wow6432Node\Microsoft\Windows\CurrentVersion\Uninstall\Microsoft Edge Update" -Force | Out-Null
	Unregister-ScheduledTask -TaskName "MicrosoftEdgeUpdateTaskMachineCore" -Confirm:$false | Out-Null
	Unregister-ScheduledTask -TaskName "MicrosoftEdgeUpdateTaskMachineUA" -Confirm:$false | Out-Null

	# remove services
	Stop-Service -Name "edgeupdate" -Force | Out-Null
	Stop-Service -Name "edgeupdatem" -Force | Out-Null
	sc.exe delete edgeupdate | Out-Null
	sc.exe delete edgeupdatem | Out-Null

	# delete the Edge Update folder
	Remove-Item -Path "C:\Program Files (x86)\Microsoft\EdgeUpdate" -Recurse -Force | Out-Null

	# revert error action preference
	$global:ErrorActionPreference = 'Continue'
}

function RemoveEdgeChromium {
	$baseKey = "HKLM:\SOFTWARE\WOW6432Node\Microsoft"
	
	# kill Edge
	$ErrorActionPreference = 'SilentlyContinue'

	Get-Process -Name MicrosoftEdgeUpdate | Stop-Process -Force
	Get-Process -Name msedge | Stop-Process -Force

	$services = @(
		'edgeupdate',
		'edgeupdatem',
		'MicrosoftEdgeElevationService'
	)

	foreach ($service in $services) {Stop-Service -Name $service -Force}
	
	$ErrorActionPreference = 'Continue'

	# check if 'experiment_control_labels' value exists and delete it if found
	$keyPath = Join-Path -Path $baseKey -ChildPath "EdgeUpdate\ClientState\{56EB18F8-B008-4CBD-B6D2-8C97FE7E9062}"
	$valueName = "experiment_control_labels"
	if (Test-Path $keyPath) {
		$valueExists = Get-ItemProperty -Path $keyPath -Name $valueName -ErrorAction SilentlyContinue
		if ($null -ne $valueExists) {
			Remove-ItemProperty -Path $keyPath -Name $valueName -Force | Out-Null
		}
	}

	# allow Edge uninstall
	$devKeyPath = Join-Path -Path $baseKey -ChildPath "EdgeUpdateDev"
	if (-not (Test-Path $devKeyPath)) { New-Item -Path $devKeyPath -ItemType "Key" -Force | Out-Null }
	Set-ItemProperty -Path $devKeyPath -Name "AllowUninstall" -Value "" -Type String -Force | Out-Null

	# uninstall Edge
	$uninstallKeyPath = Join-Path -Path $baseKey -ChildPath "Windows\CurrentVersion\Uninstall\Microsoft Edge"
	if (Test-Path $uninstallKeyPath) {
		$uninstallString = (Get-ItemProperty -Path $uninstallKeyPath).UninstallString + " --force-uninstall"
		Start-Process cmd.exe "/c $uninstallString" -WindowStyle Hidden
	}

	# remove user data
	if ($removeData) {
		$path = "$env:SystemDrive\Users\$user\AppData\Local\Microsoft\Edge"
		if (Test-Path $path) {Remove-Item $path -Force -Recurse}
	}

	# remove Edge shortcut on desktop
	# may exist for some people after a proper uninstallation
	$shortcutPath = "$env:USERPROFILE\Desktop\Microsoft Edge.lnk"
	if (Test-Path $shortcutPath) {
		Remove-Item $shortcutPath -Force
	}
}

function RemoveEdgeAppX {
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

function RemoveWebView {
	$webviewUninstallKey = @()
	$webviewHKCU = "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\Microsoft EdgeWebView"
	$webviewHKLM = "HKLM:\SOFTWARE\WOW6432Node\Microsoft\Windows\CurrentVersion\Uninstall\Microsoft EdgeWebView"
	if (Test-Path $webviewHKCU) {$webviewUninstallKey += $webviewHKCU}
	if (Test-Path $webviewHKLM) {$webviewUninstallKey += $webviewHKLM}
	foreach ($key in $webviewUninstallKey) {
		$webviewUninstallString = (Get-ItemProperty -Path $key).UninstallString + " --force-uninstall"
		Start-Process cmd.exe "/c $webviewUninstallString" -WindowStyle Hidden
	}
}

function UninstallAll {
	Write-Warning "Uninstalling Edge Chromium..."
	RemoveEdgeChromium
	if (!($AMEWizard)) {
		Write-Warning "Uninstalling AppX Edge..."
		RemoveEdgeAppx
	} else {Write-Warning "AME Wizard should uninstall AppX Edge..."}
	if ($removeWebView) {
		Write-Warning "Uninstalling Edge WebView..."
		RemoveWebView
		Write-Warning "Uninstalling Edge Update..."
		DeleteEdgeUpdate
	}
}

if ($null -ne $(whoami /user | Select-String "S-1-5-18")) {
	Write-Host "This script can't be ran as TrustedInstaller or SYSTEM."
	Write-Host "Please relaunch this script under a regular admin account.`n"
	if (!($Exit)) {PauseNul "Press any key to exit... "}
	exit 1
} else {
	if (-not ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltinRole]::Administrator)) {
		Start-Process PowerShell "-NoProfile -ExecutionPolicy Unrestricted -File `"$PSCommandPath`"" -Verb RunAs; exit
	}
}

$removeWebView = $true
$removeData = $true

if ($AMEWizard) {
	UninstallAll
	exit
}

if (!($UninstallAll)) {
	while (!($continue)) {
		Clear-Host; Write-Host "This script will remove Microsoft Edge, as once you install it, you can't normally uninstall it.
Major credit to ave9858: https://gist.github.com/ave9858/c3451d9f452389ac7607c99d45edecc6`n" -ForegroundColor Yellow

		if ($removeWebView) {$colourWeb = "Green"; $textWeb = "Selected"} else {$colourWeb = "Red"; $textWeb = "Unselected"}
		if ($removeData) {$colourData = "Green"; $textData = "Selected"} else {$colourData = "Red"; $textData = "Unselected"}
		
		Write-Host "Options:"
		Write-Host "[1] Remove Edge WebView ($textWeb)" -ForegroundColor $colourWeb
		Write-Host "[2] Remove Edge User Data ($textData)`n" -ForegroundColor $colourData
		Write-Host "Press enter to continue or use numbers to select options... " -NoNewLine
		
		$userInput = $Host.UI.RawUI.ReadKey('NoEcho,IncludeKeyDown')
		
		write-host "$input.VirtualKeyCode"
		
		switch ($userInput.VirtualKeyCode) {
			49 { # num 1
				$removeWebView = !$removeWebView
			}
			50 { # num 2
				$removeData = !$removeData
			}
			13 { # enter
				$continue = $true
			}
		}
	}
}

Clear-Host
UninstallAll

Write-Host "`nCompleted." -ForegroundColor Green
PauseNul "Press any key to exit... "
exit
