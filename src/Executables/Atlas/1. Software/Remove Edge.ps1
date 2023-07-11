[CmdletBinding()]
param (
    [Switch]$RemoveAllEdgeSilent
)

$ProgressPreference = "SilentlyContinue"

function PauseNul ($message = "Press any key to continue... ") {
	Write-Host $message -NoNewLine
	$Host.UI.RawUI.ReadKey('NoEcho,IncludeKeyDown') | Out-Null
}

function RemoveEdgeChromium {
	$baseKey = "HKLM:\SOFTWARE\WOW6432Node\Microsoft"

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
		$uninstallString = (Get-ItemProperty -Path $uninstallKeyPath).UninstallString
		Start-Process cmd.exe "/c $uninstallString --force-uninstall" -WindowStyle Hidden
	}
}

function RemoveEdgeAppX {
	# remove from Registry
	$appxStore = '\SOFTWARE\Microsoft\Windows\CurrentVersion\Appx\AppxAllUserStore'
	$pattern = "HKLM:$appxStore\InboxApplications\Microsoft.MicrosoftEdge_*_neutral__8wekyb3d8bbwe"
	$edgeAppXKey = (Get-Item -Path $pattern).PSChildName
	if (Test-Path "$pattern") { reg delete "HKLM$appxStore\InboxApplications\$edgeAppXKey" /f | Out-Null }

	# make the Edge AppX able to uninstall and uninstall
	$SID = (New-Object System.Security.Principal.NTAccount($env:USERNAME)).Translate([Security.Principal.SecurityIdentifier]).Value
	New-Item -Path "HKLM:$appxStore\EndOfLife\$SID\Microsoft.MicrosoftEdge_8wekyb3d8bbwe" -Force | Out-Null
	Get-AppxPackage -Name Microsoft.MicrosoftEdge | Remove-AppxPackage | Out-Null
	Remove-Item -Path "HKLM:$appxStore\EndOfLife\$SID\Microsoft.MicrosoftEdge_8wekyb3d8bbwe" -Force | Out-Null
}

function RemoveWebView {
	$webviewUninstallKeyPath = "HKLM:\SOFTWARE\WOW6432Node\Microsoft\Windows\CurrentVersion\Uninstall\Microsoft EdgeWebView"
	if (Test-Path $webviewUninstallKeyPath) {
		$webviewUninstallString = (Get-ItemProperty -Path $webviewUninstallKeyPath).UninstallString
		Start-Process cmd.exe "/c $webviewUninstallString --force-uninstall" -WindowStyle Hidden
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

if ($RemoveAllEdgeSilent) {
	$removeWebView = $true
	UninstallAll
}

if (!(Test-Path "C:\Program Files (x86)\Microsoft\Edge")) {
	Write-Host "It seems like Edge is already uninstalled."
	Write-Host "Running this script anyways can cause errors.`n"
	PauseNul "Press any key to continue anyways... "
}

if (-not ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltinRole]::Administrator)) {
    Start-Process PowerShell "-NoProfile -ExecutionPolicy Unrestricted -File `"$PSCommandPath`"" -Verb RunAs; exit
}

$removeWebView = $false
while (!($continue)) {
	cls
	Write-Host "This script will remove Microsoft Edge, as once you install it, you can't normally uninstall it.
Major credit to ave9858: https://gist.github.com/ave9858/c3451d9f452389ac7607c99d45edecc6`n" -ForegroundColor Yellow

	if ($removeWebView) {
		$colour = "Green"
		$text = "Selected"
	} else {
		$colour = "Red"
		$text = "Unselected"
	}
	
	Write-Host "Options:"
	Write-Host "[1] Remove Edge WebView ($text)`n" -ForegroundColor $colour
	Write-Host "Press enter to continue or use numbers to select options... " -NoNewLine
	
	$input = $Host.UI.RawUI.ReadKey('NoEcho,IncludeKeyDown')
	
	write-host "$input.VirtualKeyCode"
	
	switch ($input.VirtualKeyCode) {
		49 { # num 1
			$removeWebView = !$removeWebView
		}
		13 { # enter
			$continue = $true
		}
	}
}

cls
UninstallAll

Write-Host "`nCompleted." -ForegroundColor Green
PauseNul "Press any key to exit... "
exit