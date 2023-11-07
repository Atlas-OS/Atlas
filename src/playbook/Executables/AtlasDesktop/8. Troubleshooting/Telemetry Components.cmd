<# : batch portion
@echo off

whoami /user | find /i "S-1-5-18" > nul 2>&1 || (
	call RunAsTI.cmd "%~f0" %*
	exit /b
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

$packages = (Get-WindowsPackage -online | Where-Object { $_.PackageName -like "*NoTelemetry*" }).PackageName
if (!$?) {
	Write-Host "Failed to get packages!" -ForegroundColor Red
	PauseNul; exit 1
}
if ($null -eq $packages) {$TelemetryEnabled = '(current)'} else {$TelemetryDisabled = '(current)'}

function Menu {
	Clear-Host
	$ColourDisable = 'White'; $ColourEnable = $ColourDisable
	if ($TelemetryDisabled) {$ColourDisable = 'Gray'} else {$ColourEnable = 'Gray'}

	Write-Host @"
This script will remove or add the package that removes telemetry components in Windows.
Enabling telemetry will damage user privacy, but also is a more supported configuration of Windows.

Your computer will auto-restart if you disable it.`n
"@ -ForegroundColor Blue

	Write-Host "1) Disable telemetry components $TelemetryDisabled" -ForegroundColor $ColourDisable
	Write-Host "2) Enable telemetry components $TelemetryEnabled`n" -ForegroundColor $ColourEnable

	Write-Host "Choose 1 or 2: " -NoNewline -ForegroundColor Yellow
	$pageInput = $Host.UI.RawUI.ReadKey('NoEcho,IncludeKeyDown')

	switch ($pageInput.Character) {
		# Disable Defender
		1 {
			if ($TelemetryDisabled) {Menu}
			Clear-Host; Write-Host "Disabling telemetry... Your computer will auto-restart.`n" -ForegroundColor Green
			@REM & "$env:windir\AtlasModules\PackagesEnvironment\winrePackages.ps1" -EverythingButDefender
			if ($lastexitcode -ne 1) {
				Write-Host "Something went wrong disabling telemetry." -ForegroundColor Red
				Write-Host "See the documentation: https://docs.atlasos.net/troubleshooting-and-faq/failed-component-removal"
				PauseNul; exit $exitcode
			}
			PauseNul
		}
		# Enable Defender
		2 {
			if ($TelemetryEnabled) {Menu}
			Clear-Host
			Write-Host "Enabling telemetry..." -ForegroundColor Yellow
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