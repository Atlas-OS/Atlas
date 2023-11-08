<#
	.SYNOPSIS
	Uninstalls Edge and Edge-related components.

	.Description
	Uninstalls Edge and Edge-related components in a non-forceful manner, based upon the switches or user choices.

	.PARAMETER UninstallAll
	Uninstalls everything, including WebView, Update, etc... without interaction, including Edge user data.

	.PARAMETER UninstallEdge
	Uninstalls Edge-only, leaving the Edgeuser data, without interaction.

	.PARAMETER Exit
	When combined with other parameters, this exits the script (even if there's errors) on completion.

	.PARAMETER KeepAppX
	Keeps the AppX, in case you want to use alternative AppX removal methods.

	.LINK
	https://github.com/he3als/EdgeRemover

	.LINK
	https://gist.github.com/ave9858/c3451d9f452389ac7607c99d45edecc6
#>

param (
	[switch]$UninstallAll,
	[switch]$UninstallEdge,
	[switch]$Exit,
	[switch]$KeepAppX
)

$version = '1.6'
$host.UI.RawUI.WindowTitle = "EdgeRemover $version"

# credit to ave9858 for Edge removal method: https://gist.github.com/ave9858/c3451d9f452389ac7607c99d45edecc6
$ProgressPreference = "SilentlyContinue"
$user = $env:USERNAME
$SID = (New-Object System.Security.Principal.NTAccount($user)).Translate([Security.Principal.SecurityIdentifier]).Value
$EdgeRemoverReg = 'HKLM:\SOFTWARE\EdgeRemover'

if ($Exit -and ((-not $UninstallAll) -and (-not $UninstallEdge))) {
    $Exit = $false
}

function PauseNul ($message = "Press any key to continue... ") {
	Write-Host $message -NoNewLine
	$Host.UI.RawUI.ReadKey('NoEcho,IncludeKeyDown') | Out-Null
}

function BlockEdgeInstallandUpdates {
	# lots of these will only apply when domain joined and such
	# further research is needed generally
	# https://learn.microsoft.com/en-us/deployedge/microsoft-edge-update-policies

	$EdgeInstallUID = '{56EB18F8-B008-4CBD-B6D2-8C97FE7E9062}'
	$WebViewInstallUID = '{F3017226-FE2A-4295-8BDF-00C3A9A7E4C5}'
	$EdgeUpdatePolicyKey = 'HKLM:\SOFTWARE\Policies\Microsoft\EdgeUpdate'

	# clear key
	Remove-Item -Path $EdgeUpdatePolicyKey -Recurse -Force -EA SilentlyContinue
	New-Item -Path $EdgeUpdatePolicyKey -Force | Out-Null

	if ($removeEdge) {
		# set misc options
		Set-ItemProperty -Path $EdgeUpdatePolicyKey -Name 'CreateDesktopShortcutDefault' -Value 0 -Type Dword -Force

		# block Edge install/update
		Set-ItemProperty -Path $EdgeUpdatePolicyKey -Name "Install$EdgeInstallUID" -Value 0 -Type Dword -Force
	}

	$completeBlockPolicies = @{
		# block Edge updates
		"Update$EdgeInstallUID" = 2

		# block WebView install/update
		"Install$WebViewInstallUID" = 0
		"Update$WebViewInstallUID" = 2

		# block update checks
		"AutoUpdateCheckPeriodMinutes" = 0
		"UpdatesSuppressedStartMin" = 0
		"UpdatesSuppressedStartHour" = 0
		"UpdatesSuppressedDurationMin" = 1440
	}

	New-Item -Path $EdgeRemoverReg -Force -EA SilentlyContinue | Out-Null
	$EdgeUpdateDisabled = 'HKLM:\SOFTWARE\EdgeRemover\EdgeUpdateDisabled'
	$EdgeUpdateOrchestrator = 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\WindowsUpdate\Orchestrator\UScheduler\EdgeUpdate'
	if ($blockEdge) {
		foreach ($a in $completeBlockPolicies.Keys) {
			Set-ItemProperty -Path $EdgeUpdatePolicyKey -Name $a -Value $completeBlockPolicies.$a -Type Dword -Force
		}

		if ((Test-Path $EdgeUpdateOrchestrator) -and (Test-Path $EdgeUpdateDisabled)) {
			Remove-Item -Path $EdgeUpdateDisabled -Force
		}
		if (Test-Path $EdgeUpdateOrchestrator) { Move-Item -Path $EdgeUpdateOrchestrator -Destination $EdgeUpdateDisabled -Force }
	} else {
		if (!(Test-Path $EdgeUpdateOrchestrator) -and (Test-Path $EdgeUpdateDisabled)) {
			Move-Item -Path $EdgeUpdateDisabled -Destination $EdgeUpdateOrchestrator -Force
		}
	}
}

function DeleteEdgeUpdate {
	# surpress errors as some Edge Update components may not exist
	$global:ErrorActionPreference = 'SilentlyContinue'

	# remove scheduled tasks
	Remove-Item -Path "HKLM:\SOFTWARE\Wow6432Node\Microsoft\Windows\CurrentVersion\Uninstall\Microsoft Edge Update" -Force | Out-Null
	Unregister-ScheduledTask -TaskName "MicrosoftEdgeUpdateTaskMachineCore" -Confirm:$false | Out-Null
	Unregister-ScheduledTask -TaskName "MicrosoftEdgeUpdateTaskMachineUA" -Confirm:$false | Out-Null

	if ($removeWebView) {
		# delete edge services
		foreach ($service in $services) {
			sc.exe delete $service
		}
		
		# delete the edgeupdate folder
		Remove-Item -Path "$env:SystemDrive\Program Files (x86)\Microsoft\EdgeUpdate" -Recurse -Force | Out-Null
	}

	# revert error action preference
	$global:ErrorActionPreference = 'Continue'
}

function RemoveEdgeChromium {
	$baseKey = "HKLM:\SOFTWARE\WOW6432Node\Microsoft"
	$ErrorActionPreference = 'SilentlyContinue'

	# terminate Edge processes
	$services = (Get-Service -Name "*edge*" | Where-Object {$_.DisplayName -like "*Microsoft Edge*"}).Name
	$processes = (Get-Process | Where-Object {($_.Path -like "$env:SystemDrive\Program Files (x86)\Microsoft\*") -or ($_.Name -like "*msedge*")}).Id
	foreach ($process in $processes) {
		Stop-Process -Id $process -Force
	}
	foreach ($service in $services) {
		Stop-Service -Name $service -Force
	}

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
		Start-Process cmd.exe "/c $uninstallString" -WindowStyle Hidden 2>&1 | Out-Null
	}

	# remove user data
	if ($removeData) {
		$path = "$env:LOCALAPPDATA\Microsoft\Edge"
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
	$edges = @(); $bho = @(); $edgeupdates = @(); 'LocalApplicationData','ProgramFilesX86','ProgramFiles' | foreach {
    	$folder = [Environment]::GetFolderPath($_)
    	$edges += dir "$folder\Microsoft\Edge*\setup.exe" -rec -ea 0 | where {$_ -like '*EdgeWebView*'}
    }

    foreach ($setup in $edges) {
    	$target = "--msedgewebview"
    	$sulevel = ('--system-level','--user-level')[$setup -like '*\AppData\Local\*']
   		$removal = "--uninstall $target $sulevel --verbose-logging --force-uninstall"
    	start -wait $setup -args $removal
    }
}

function UninstallAll {
	if ($removeEdge) {
		Write-Warning "Uninstalling Edge Chromium..."
		RemoveEdgeChromium
		if (!($KeepAppX)) {
			Write-Warning "Uninstalling AppX Edge..."
			RemoveEdgeAppx
		} else {Write-Warning "AppX Edge is being left, there might be a stub..."}
	}
	if ($removeWebView) {
		Write-Warning "Uninstalling Edge WebView..."
		RemoveWebView
	}
	if ($removeEdge -and $removeWebView) {
		Write-Warning "Uninstalling Edge Update..."
		DeleteEdgeUpdate
	}
	Write-Warning "Applying EdgeUpdate policies..."
	BlockEdgeInstallandUpdates
}

function Completed {
	Write-Host "`nCompleted." -ForegroundColor Green
	if (!$Exit) {
		PauseNul "Press any key to exit... "
	}
	exit
}

if ($null -ne $(whoami /user | Select-String "S-1-5-18")) {
	Write-Host "This script can't be ran as TrustedInstaller or SYSTEM. -ForegroundColor Yellow
Please relaunch this script under a regular admin account.`n" -ForegroundColor Yellow
	if (!($Exit)) {PauseNul "Press any key to exit... "}
	exit 1
} else {
	if (-not ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltinRole]::Administrator)) {
		Start-Process cmd "/c powershell -NoP -EP Unrestricted -File `"$PSCommandPath`"" -Verb RunAs; exit
	}
}

if ($UninstallAll) {
	$removeEdge = $true
	$removeWebView = $true
	$removeData = $true
	$blockEdge = $true
	UninstallAll
	Completed
}

if ($UninstallEdge) {
	$removeEdge = $true
	$removeWebView = $false
	$removeData = $false
	UninstallAll
	Completed
}

# set defaults
$removeEdge = $true
$removeWebView = $false
$removeData = $false
$blockEdge = $false

while (!($continue)) {
	Clear-Host; Write-Host "This script will remove Microsoft Edge, as once it's installed, you can't uninstall it.`n" -ForegroundColor Blue

	Write-Host "Selecting nothing will clear all install and update blocks." -ForegroundColor Yellow
	Write-Host "You can reinstall WebView and Edge from the internet in the future.`n" -ForegroundColor Yellow

	if ($removeEdge) {$colourEdge = "Green"; $textEdge = "Selected"} else {$colourEdge = "Red"; $textEdge = "Unselected"}
	if ($removeWebView) {$colourWeb = "Green"; $textWeb = "Selected"} else {$colourWeb = "Red"; $textWeb = "Unselected"}
	if ($removeData) {$colourData = "Green"; $textData = "Selected"} else {$colourData = "Red"; $textData = "Unselected"}
	if ($blockEdge) {$colourBlock = "Green"; $textBlock = "Selected"} else {$colourBlock = "Red"; $textBlock = "Unselected"}

	Write-Host "Options:"
	Write-Host "[1] Remove Edge ($textEdge)" -ForegroundColor $colourEdge
	Write-Host "[2] Remove Edge WebView ($textWeb)" -ForegroundColor $colourWeb
	Write-Host "[3] Remove Edge User Data ($textData)" -ForegroundColor $colourData
	Write-Host "[4] Block WebView install & Edge updates ($textBlock)" -ForegroundColor $colourBlock
	Write-Host "`nPress enter to continue or use numbers to select options... " -NoNewLine

	$userInput = $Host.UI.RawUI.ReadKey('NoEcho,IncludeKeyDown')

	switch ($userInput.VirtualKeyCode) {
		49 { # num 1
			$removeEdge = !$removeEdge
		}
		50 { # num 2
			$removeWebView = !$removeWebView
		}
		51 { # num 3
			$removeData = !$removeData
		}
		52 { # num 4
			$blockEdge = !$blockEdge
		}
		13 { # enter
			$continue = $true
		}
	}
}

Clear-Host
UninstallAll
Completed
