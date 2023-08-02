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
		exit /b 0
	)
)

set args= & set "args1=%*"
if defined args1 set "args=%args1:"='%"
powershell -nop "& ([Scriptblock]::Create((Get-Content '%~f0' -Raw))) %args%"
exit /b %errorlevel%
: end batch / begin PowerShell #>

param (
    [switch]$Enable,
    [switch]$Disable
)

$AtlasPackageName = 'Z-Atlas-NoDefender-Package'

$AtlasModules = "$env:windir\AtlasModules"
$onlineSxS = "$AtlasModules\Scripts\online-sxs.cmd"
$packagesPath = "$AtlasModules\Packages"

function PauseNul ($message = "Press any key to exit... ") {
	Write-Host $message -NoNewLine
	$Host.UI.RawUI.ReadKey('NoEcho,IncludeKeyDown') | Out-Null
}

function UninstallPackage {
	param (
		[switch]$Disable
	)

	$packages = (Get-WindowsPackage -online | Where-Object { $_.PackageName -like "*$AtlasPackageName*" }).PackageName
	if ($null -eq $packages) {
		if (!($Disable)) { Write-Host "No Defender package is seemingly installed." -ForegroundColor Yellow }
		return
	} else {
		foreach ($package in $packages) {
			try {
				Remove-WindowsPackage -Online -PackageName $package *>$null
			} catch {
				Write-Host "Something went wrong removing the package: $package" -ForegroundColor Red
				Write-Host "$_`n" -ForegroundColor Red
				if ($Enable -or $Disable) {return 1} else {PauseNul; exit 1}
			}
		}
	}
}

function InstallPackage {
	$latestCabPath = (Get-ChildItem -Path $packagesPath -Filter "*$AtlasPackageName*.cab" | Sort-Object | Select-Object -Last 1).FullName
	Write-Warning "Installing package to remove Defender..."
	try {
		& $onlineSxS "$latestCabPath" -Silent
	} catch {
		Write-Host "`nSomething went wrong whilst adding the Defender package.`nPlease report the error above to the Atlas team." -ForegroundColor Yellow
		PauseNul
		exit 1
	}
}

function SetDefenderConfigInRegistry {
	# -SetValue $false = Defender disabled
	# -SetValue $true = Defender enabled
	param (
		[switch]$GetValue,
		[bool]$SetValue
	)

	$registryPath = "HKLM:\SOFTWARE\Atlas"
	$valueName = "DefenderDisabled"

	if ($GetValue) {
		if (Test-Path -Path $registryPath) {
			$value = Get-ItemProperty -Path $registryPath -Name $valueName EA SilentlyContinue
			if ($null -ne $value) {
				if ($value.$DefenderDisabled -eq 0) {
					$global:DefenderDisabled = "(current)"
				} elseif ($value.$DefenderDisabled -eq 1) {
					$global:DefenderEnabled = "(current)"
				}
			}
		}
		return
	}

	if ($SetValue -eq $true) {$value = '1'} else {$value = '0'}
	New-Item -Path $registryPath -Force -EA SilentlyContinue | Out-Null
	Set-ItemProperty -Path $registryPath -Name "Defender" -Value $value -Type DWord -Force
}

function Finish {
	Write-Host "`nCompleted!" -ForegroundColor Green
	choice /c yn /n /m "Would you like to restart now to apply the changes? [Y/N] "
	if ($lastexitcode -eq 1) {Restart-Computer} else {
		Write-Host "`nChanges will apply after next restart." -ForegroundColor Yellow
		Start-Sleep 2; exit
	}
}

if ($Disable) {InstallPackage; SetDefenderConfigInRegistry -SetValue $false; exit} elseif ($Enable) {UninstallPackage; SetDefenderConfigInRegistry -SetValue $true; exit}

function Menu {
	Clear-Host
	SetDefenderConfigInRegistry -GetValue
	Write-Host "1) Disable Defender $DefenderDisabled
2) Enable Defender $DefenderEnabled`n"

	Write-Host "Choose 1 or 2: " -NoNewline -ForegroundColor Yellow
	$pageInput = $Host.UI.RawUI.ReadKey('NoEcho,IncludeKeyDown')

	switch ($pageInput.Character) {
		# Disable Defender
		1 {
			Clear-Host
			Write-Host "Are you sure that you want to disable Defender?" -ForegroundColor Red
			Write-Host "Although disabling Windows Defender will improve performance and convienience, it's important for security.`n"
			
			Pause; Clear-Host; InstallPackage

			SetDefenderConfigInRegistry -SetValue $false
			Finish
		}
		# Enable Defender
		2 {
			Clear-Host; UninstallPackage; SetDefenderConfigInRegistry -SetValue $true; Finish
		}
		default {
			# Do nothing
			Menu
		}
	}
}

Menu