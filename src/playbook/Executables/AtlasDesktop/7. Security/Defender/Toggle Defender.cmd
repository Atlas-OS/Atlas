<# : batch portion
@echo off

if "%~1"=="-Help" (goto help) else (if "%~1"=="-help" (goto help) else (if "%~1"=="/h" (goto help) else (goto main)))

:help
echo Usage = Toggle Defender.cmd [-Help] [-Enable] [-Disable]
exit /b

:main
if "%*"=="" (
	fltmc >nul 2>&1 || (
		echo Administrator privileges are required.
		PowerShell Start -Verb RunAs '%0' 2> nul || (
			echo You must run this script as admin.
			pause & exit /b 1
		)
		exit /b
	)
)

set args= & set "args1=%*"
if defined args1 set "args=%args1:"='%"
powershell -nop "& ([Scriptblock]::Create((Get-Content '%~f0' -Raw))) %args%"
exit /b %errorlevel%
: end batch / begin PowerShell #>

param (
    [switch]$Enable,
    [switch]$Disable,
    [switch]$SafeMode,
	[switch]$DisableFailedMessage
)

$AtlasPackageName = 'Z-Atlas-NoDefender-Package'

$AtlasModules = "$env:windir\AtlasModules"
$onlineSxS = "$AtlasModules\Scripts\online-sxs.cmd"
$packagesPath = "$AtlasModules\Packages"
$ProgressPreference = 'SilentlyContinue'
$winlogon = "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Winlogon"
$taskName = 'RemoveDefenderFailedAtlas'

function PauseNul ($message = "Press any key to exit... ") {
	Write-Host $message -NoNewLine
	$Host.UI.RawUI.ReadKey('NoEcho,IncludeKeyDown') | Out-Null
}

$packages = (Get-WindowsPackage -online | Where-Object { $_.PackageName -like "*$AtlasPackageName*" }).PackageName
if (!($?)) {
	Write-Host "Failed to get packages!" -ForegroundColor Red
	if (!($Silent)) {PauseNul}; exit 1
}
if ($null -eq $packages) {$DefenderEnabled = '(current)'} else {$DefenderDisabled = '(current)'}


function SetSafeMode {
	Start-Process -File 'bcdedit' -ArgumentList '/set {current} safeboot minimal' -WindowStyle Hidden
	Set-ItemProperty -Path $winlogon -Name Shell -Value "$env:WinDir\AtlasDesktop\7. Security\Defender\Toggle Defender.cmd -SafeMode"
	Restart-Computer
	exit
}

function ExitSafeMode {
	Start-Process -File "bcdedit" -ArgumentList "/deletevalue {current} safeboot" -WindowStyle Hidden
	Set-ItemProperty -Path $winlogon -Name Shell -Value 'explorer.exe'
	shutdown /f /r /t 0
	exit
}

function RemoveFailureTask {
	Unregister-ScheduledTask -TaskName $taskName -Confirm:$false
}

function UninstallPackage {
	param (
		[switch]$Disable
	)
	foreach ($package in $packages) {
		try {
			Remove-WindowsPackage -Online -PackageName $package -NoRestart -LogLevel 1 *>$null
		} catch {
			Write-Host "Something went wrong removing the package: $package" -ForegroundColor Red
			Write-Host "$_`n" -ForegroundColor Red
			if (!($Silent)) {PauseNul}; exit 1
		}
	}
}

function InstallPackage {
	$latestCabPath = (Get-ChildItem -Path $packagesPath -Filter "*$AtlasPackageName*.cab" | Sort-Object | Select-Object -Last 1).FullName
	Write-Warning "Installing package to remove Defender..."
	
	$output = & $onlineSxS "$latestCabPath" -Silent
	if ($LASTEXITCODE -ne 0) {
		if ((Get-WmiObject -Class Win32_ComputerSystem).BootupState -ne 'Normal boot') {
			Clear-Host
			Write-Host $($output -join "`r`n") -ForegroundColor Red

			Write-Host "`nSomething went wrong whilst adding the Defender package.`nPlease see the documentation: docs.atlasos.net/troubleshooting/common-issues/defender-disabling`n" -ForegroundColor Yellow
			PauseNul "Press any key to exit safe mode... "
			ExitSafeMode
		}

		if ($Silent) {
			Write-Warning "Registring scheduled task to prompt user to disable Defender next reboot, as it has failed..."
			$action = New-ScheduledTaskAction -Execute "$env:windir\System32\cmd.exe" -Argument '/c "%windir%\AtlasDesktop\7. Security\Defender\Toggle Defender.cmd" -DisableFailedMessage'
			$settings = New-ScheduledTaskSettingsSet -AllowStartIfOnBatteries -DontStopIfGoingOnBatteries
			$trigger = New-ScheduledTaskTrigger -AtLogon
			Register-ScheduledTask -TaskName $taskName -Trigger $trigger -Action $action -Settings $settings -User $env:USERNAME -RunLevel Highest -Force | Out-Null
			exit 1
		} else {
			Write-Host "`nSomething went wrong whilst adding the Defender package." -ForegroundColor Yellow
			choice /c yn /n /m "Would you like to try rebooting into 'Safe mode' to apply the changes? [Y/N] "
			if ($lastexitcode -eq 1) {
				SetSafeMode
			} else {
				exit 1
			}
		}
	}
}

function Finish {
	Write-Host "`nCompleted!" -ForegroundColor Green
	choice /c yn /n /m "Would you like to restart now to apply the changes? [Y/N] "
	if ($lastexitcode -eq 1) {
		Restart-Computer
	} else {
		Write-Host "`nChanges will apply after next restart." -ForegroundColor Yellow
		Start-Sleep 2; exit
	}
	exit
}

if ($DisableFailedMessage) {
	# hide window
	powershell -WindowStyle Hidden exit

	$WindowTitle = 'Failed disabling Defender - Atlas'

	$Message = @'
Disabling Defender failed, this is most likely due to Windows somehow preventing it from happening.

Would you like to attempt to disable Defender in Safe Mode and restart now?
'@

	$sh = New-Object -ComObject "Wscript.Shell"
	$intButton = $sh.Popup($Message,0,$WindowTitle,4+48+4096)

	RemoveFailureTask
	if ($intButton -eq '6') { SetSafeMode }
	exit
}

if ($Enable -or $Disable) {$Silent = $true}

if ($Disable) {InstallPackage; exit} elseif ($Enable) {UninstallPackage; exit}
if ($SafeMode) {
	InstallPackage
	Write-Host "`nCompleted!" -ForegroundColor Green
	Write-Host "Restarting in 3 seconds..."
	Start-Sleep 3
	ExitSafeMode
}

function Menu {
	Clear-Host
	$ColourDisable = 'White'; $ColourEnable = $ColourDisable
	if ($DefenderDisabled) {$ColourDisable = 'Gray'} else {$ColourEnable = 'Gray'}

	Write-Host "1) Disable Defender $DefenderDisabled" -ForegroundColor $ColourDisable
	Write-Host "2) Enable Defender $DefenderEnabled`n" -ForegroundColor $ColourEnable

	Write-Host "Choose 1 or 2: " -NoNewline -ForegroundColor Yellow
	$pageInput = $Host.UI.RawUI.ReadKey('NoEcho,IncludeKeyDown')

	switch ($pageInput.Character) {
		# Disable Defender
		1 {
			if ($DefenderDisabled) {Menu}
			Clear-Host
			Write-Host "Are you sure that you want to disable Defender?" -ForegroundColor Red
			Write-Host "Although disabling Windows Defender will improve performance and convienience, it's important for security.`n"
			
			Pause
			Clear-Host
			InstallPackage
			Finish
		}
		# Enable Defender
		2 {
			if ($DefenderEnabled) {Menu}
			Clear-Host
			UninstallPackage
			Finish
		}
		default {
			# Do nothing
			Menu
		}
	}
}

Menu