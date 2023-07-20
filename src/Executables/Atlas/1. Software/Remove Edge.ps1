[CmdletBinding()]
param (
	[Switch]$Setup
)

$ProgressPreference = "SilentlyContinue"

function PauseNul ($message = "Press any key to continue... ") {
	Write-Host $message -NoNewLine
	$Host.UI.RawUI.ReadKey('NoEcho,IncludeKeyDown') | Out-Null
}

# removing Edge Chromium & WebView is meant to be compatible with TrustedInstaller for AME Wizard
# running the uninstaller as TrustedInstaller causes shortcuts and other things not to be removed properly
function RunAsScheduledTask {
	[CmdletBinding()]
	param (
		[String]$Command
	)
	$user = (Get-CimInstance -ClassName Win32_ComputerSystem | Select-Object -ExpandProperty UserName) -replace ".*\\"
	$action = New-ScheduledTaskAction -Execute "$env:windir\System32\cmd.exe" -Argument "/c $Command"
	$settings = New-ScheduledTaskSettingsSet -AllowStartIfOnBatteries -DontStopIfGoingOnBatteries
	$title = "RemoveEdge $(Get-Random -minimum 9999999999)"
	Register-ScheduledTask -TaskName $title -Action $action -Settings $settings -User $user -RunLevel Highest -Force | Start-ScheduledTask | Out-Null
	Unregister-ScheduledTask -TaskName $title -Confirm:$false | Out-Null
}

function RemoveEdgeChromium {
	[CmdletBinding()]
	param (
		[Switch]$AsTask
	)
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
		if ($valueExists -ne $null) {
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
		# create a scheduled task as current user so that it works properly with TI perms
		if ($AsTask) {RunAsScheduledTask -Command $uninstallString} else {
			Start-Process cmd.exe "/c $uninstallString" -WindowStyle Hidden
		}
	}
	
	# remove user data
	if ($removeData) {
		$path = "$env:LOCALAPPDATA\Microsoft\Edge"
		if (Test-Path $path) {Remove-Item $path -Force -Recurse}
	}
}

function RemoveEdgeAppX {
	# remove from Registry
	$appxStore = '\SOFTWARE\Microsoft\Windows\CurrentVersion\Appx\AppxAllUserStore'
	$pattern = "HKLM:$appxStore\InboxApplications\Microsoft.MicrosoftEdge_*_neutral__8wekyb3d8bbwe"
	$edgeAppXKey = (Get-Item -Path $pattern).PSChildName
	if (Test-Path "$pattern") { reg delete "HKLM$appxStore\InboxApplications\$edgeAppXKey" /f | Out-Null }

	# make the Edge AppX able to uninstall and uninstall
	$user = (Get-CimInstance -ClassName Win32_ComputerSystem | Select-Object -ExpandProperty UserName) -replace ".*\\"
	$SID = (New-Object System.Security.Principal.NTAccount($env:USERNAME)).Translate([Security.Principal.SecurityIdentifier]).Value
	New-Item -Path "HKLM:$appxStore\EndOfLife\$SID\Microsoft.MicrosoftEdge_8wekyb3d8bbwe" -Force | Out-Null
	Get-AppxPackage -Name Microsoft.MicrosoftEdge | Remove-AppxPackage | Out-Null
	Remove-Item -Path "HKLM:$appxStore\EndOfLife\$SID\Microsoft.MicrosoftEdge_8wekyb3d8bbwe" -Force | Out-Null
}

function RemoveWebView {
	[CmdletBinding()]
	param (
		[Switch]$AsTask
	)
	$webviewUninstallKeyPath = "HKLM:\SOFTWARE\WOW6432Node\Microsoft\Windows\CurrentVersion\Uninstall\Microsoft EdgeWebView"
	if (Test-Path $webviewUninstallKeyPath) {
		$webviewUninstallString = (Get-ItemProperty -Path $webviewUninstallKeyPath).UninstallString + " --force-uninstall"
		if ($AsTask) {RunAsScheduledTask -Command $webviewUninstallString} else {
			Start-Process cmd.exe "/c $uninstallString" -WindowStyle Hidden
		}
	}
}

function UninstallAll {
	Write-Warning "Uninstalling Edge Chromium..."
	RemoveEdgeChromium
	Write-Warning "Uninstalling AppX Edge..."
	RemoveEdgeAppx
	if ($removeWebView) {
		Write-Warning "Uninstalling Edge WebView..."
		RemoveWebView
	}
}

if ($Setup) {
	if ((whoami /user) -like "*S-1-5-18*") {
		$user = (Get-CimInstance -ClassName Win32_ComputerSystem | Select-Object -ExpandProperty UserName) -replace ".*\\"
		$action = New-ScheduledTaskAction -Execute "$env:windir\System32\WindowsPowerShell\v1.0\powershell.exe" -Argument '-NoP -EP Unrestricted -WindowStyle Hidden -File "C:\Users\Default\Desktop\Atlas\1. Software\Remove Edge.ps1" -Setup'
		$settings = New-ScheduledTaskSettingsSet -AllowStartIfOnBatteries -DontStopIfGoingOnBatteries
		$title = "RemoveEdge $(Get-Random -minimum 9999999999)"
		Register-ScheduledTask -TaskName $title -Action $action -Settings $settings -User $user -RunLevel Highest -Force | Start-ScheduledTask | Out-Null
		Unregister-ScheduledTask -TaskName $title -Confirm:$false | Out-Null
		exit
	}
	$removeData = $true
	UnistallAll
	exit
}

if (-not ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltinRole]::Administrator)) {
    Start-Process PowerShell "-NoProfile -ExecutionPolicy Unrestricted -File `"$PSCommandPath`"" -Verb RunAs; exit
}

if ($(whoami /user | Select-String "S-1-5-18") -ne $null) {
	Write-Host "This script can't be ran as TrustedInstaller or SYSTEM."
	Write-Host "Please relaunch this script under a regular admin account.`n"
	PauseNul "Press any key to exit... "
	exit 1
}

$removeWebView = $false
$removeData = $true
while (!($continue)) {
	cls; Write-Host "This script will remove Microsoft Edge, as once you install it, you can't normally uninstall it.
Major credit to ave9858: https://gist.github.com/ave9858/c3451d9f452389ac7607c99d45edecc6`n" -ForegroundColor Yellow

	if ($removeWebView) {$colourWeb = "Green"; $textWeb = "Selected"} else {$colourWeb = "Red"; $textWeb = "Unselected"}
	if ($removeData) {$colourData = "Green"; $textData = "Selected"} else {$colourData = "Red"; $textData = "Unselected"}
	
	Write-Host "Options:"
	Write-Host "[1] Remove Edge WebView ($textWeb)" -ForegroundColor $colourWeb
	Write-Host "[2] Remove Edge User Data ($textData)`n" -ForegroundColor $colourData
	Write-Host "Press enter to continue or use numbers to select options... " -NoNewLine
	
	$input = $Host.UI.RawUI.ReadKey('NoEcho,IncludeKeyDown')
	
	write-host "$input.VirtualKeyCode"
	
	switch ($input.VirtualKeyCode) {
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

cls; UninstallAll

Write-Host "`nCompleted." -ForegroundColor Green
PauseNul "Press any key to exit... "
exit