<# : batch portion
@echo off

if "%~1" == "-Help" (goto help) else (if "%~1" == "-help" (goto help) else (if "%~1" == "/h" (goto help) else (goto main)))

:help
echo Usage = Toggle Defender.cmd [-Help] [-Enable] [-Disable]
exit /b

:main
if "%*" == "" (
	fltmc > nul 2>&1 || (
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
exit /b %ERRORLEVEL%
: end batch / begin PowerShell #>

$ProgressPreference = 'SilentlyContinue'
function PauseNul ($message = "Press any key to exit... ") {
	Write-Host $message -NoNewLine
	$Host.UI.RawUI.ReadKey('NoEcho,IncludeKeyDown') | Out-Null
}

$packages = (Get-WindowsPackage -online | Where-Object { $_.PackageName -like "*NoDefender*" }).PackageName
if (!($?)) {
	Write-Host "Failed to get packages!" -ForegroundColor Red
	PauseNul; exit 1
}
if ($null -eq $packages) {$DefenderEnabled = '(current)'} else {$DefenderDisabled = '(current)'}

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
			Write-Host "Your computer will restart automatically if you proceed.`n" -ForegroundColor Yellow
			
			Pause; Clear-Host
			Write-Host "Disabling Defender... Your computer will auto-restart." -ForegroundColor Green
			& "$env:windir\AtlasModules\PackagesEnvironment\winrePackages.ps1" -DefenderOnly
			if ($lastexitcode -ne 1) {
				Write-Host "Something went wrong disabling Defender." -ForegroundColor Red
				Write-Host "See the documentation: https://docs.atlasos.net/troubleshooting-and-faq/failed-component-removal"
				PauseNul; exit $exitcode
			}
			PauseNul
		}
		# Enable Defender
		2 {
			if ($DefenderEnabled) {Menu}
			Clear-Host
			foreach ($package in $packages) {
				try {
					Remove-WindowsPackage -Online -PackageName $package -NoRestart -LogLevel 1 *>$null
				} catch {
					Write-Host "Something went wrong removing the package: $package" -ForegroundColor Red
					Write-Host "$_`n" -ForegroundColor Red
					PauseNul; exit 1
				}
			}

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
		default {
			# Do nothing
			Menu
		}
	}
}

Menu