[CmdletBinding()]
param (
    [Switch]$RemoveEdge
)

$ProgressPreference = "SilentlyContinue"

function PauseNul ($message = "Press any key to continue... ") {
	Write-Host $message -NoNewLine
	$Host.UI.RawUI.ReadKey('NoEcho,IncludeKeyDown') | Out-Null
}

function RemoveEdgeChromium {
	$regView = [Microsoft.Win32.RegistryView]::Registry32
	$microsoft = [Microsoft.Win32.RegistryKey]::OpenBaseKey([Microsoft.Win32.RegistryHive]::LocalMachine, $regView).
	OpenSubKey('SOFTWARE\Microsoft', $true)

	$edgeClient = $microsoft.OpenSubKey('EdgeUpdate\ClientState\{56EB18F8-B008-4CBD-B6D2-8C97FE7E9062}', $true)
	if ($null -ne $edgeClient.GetValue('experiment_control_labels')) {
		$edgeClient.DeleteValue('experiment_control_labels')
	}

	$microsoft.CreateSubKey('EdgeUpdateDev').SetValue('AllowUninstall', '')

	$uninstallRegKey = $microsoft.OpenSubKey('Windows\CurrentVersion\Uninstall\Microsoft Edge')
	$uninstallString = $uninstallRegKey.GetValue('UninstallString') + ' --force-uninstall'
	Start-Process cmd.exe "/c $uninstallString" -WindowStyle Hidden
}

function RemoveEdgeAppX {
	$appxStore = '\SOFTWARE\Microsoft\Windows\CurrentVersion\Appx\AppxAllUserStore'
	$pattern = "HKLM:$appxStore\InboxApplications\Microsoft.MicrosoftEdge_*_neutral__8wekyb3d8bbwe"
	$key = (Get-Item -Path $pattern).PSChildName
	reg delete "HKLM$appxStore\InboxApplications\$key" /f | Out-Null

	$SID = (New-Object System.Security.Principal.NTAccount($env:USERNAME)).Translate([Security.Principal.SecurityIdentifier]).Value

	New-Item -Path "HKLM:$appxStore\EndOfLife\$SID\Microsoft.MicrosoftEdge_8wekyb3d8bbwe" -Force | Out-Null

	Get-AppxPackage -Name Microsoft.MicrosoftEdge | Remove-AppxPackage | Out-Null

	Remove-Item -Path "HKLM:$appxStore\EndOfLife\$SID\Microsoft.MicrosoftEdge_8wekyb3d8bbwe" -Force | Out-Null
}

if ($RemoveEdge) {
	RemoveEdgeChromium
	RemoveEdgeAppx
	exit
}

if (!(Test-Path "C:\Program Files (x86)\Microsoft\Edge")) {
	Write-Host "It seems like Edge is already uninstalled."
	Write-Host "Running this script anyways can cause errors.`n"
	PauseNul "Press any key to continue anyways... "
}

if (-not ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltinRole]::Administrator)) {
    Start-Process PowerShell "-NoProfile -ExecutionPolicy Unrestricted -File `"$PSCommandPath`"" -Verb RunAs; exit
}

Write-Host "This script will remove Microsoft Edge, as once you install it, you can't normally uninstall it.
Major credit to ave9858: https://gist.github.com/ave9858/c3451d9f452389ac7607c99d45edecc6`n"
PauseNul; cls

RemoveEdgeChromium
RemoveEdgeAppx

Write-Host "Completed." -ForegroundColor Green
PauseNul "Press any key to exit... "
exit