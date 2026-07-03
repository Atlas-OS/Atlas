@echo off
setlocal

set "settingName=PauseUpdates"
set "stateValue=1"
set "scriptPath=%~f0"

set "___args="%~f0" %*"
fltmc > nul 2>&1 || (
	echo Administrator privileges are required.
	powershell -c "Start-Process -Verb RunAs -FilePath 'cmd' -ArgumentList """/c $env:___args"""" 2> nul || (
		echo You must run this script as admin.
		if "%*"=="" pause
		exit /b 1
	)
	exit /b
)

if not "%~1"=="/silent" call "%windir%\AtlasModules\Scripts\serviceWarning.cmd" %*

reg add "HKLM\SOFTWARE\AtlasOS\Services\%settingName%" /v state /t REG_DWORD /d %stateValue% /f >nul
reg add "HKLM\SOFTWARE\AtlasOS\Services\%settingName%" /v path /t REG_SZ /d "%scriptPath%" /f >nul
reg add "HKLM\SOFTWARE\AtlasOS\Services\%settingName%" /v days /t REG_DWORD /d 356000 /f >nul

echo Applying Windows Update pause policies...

reg add "HKLM\SOFTWARE\Microsoft\WindowsUpdate\UpdatePolicy\Settings" /v PausedFeatureStatus /t REG_DWORD /d 1 /f > nul
reg add "HKLM\SOFTWARE\Microsoft\WindowsUpdate\UpdatePolicy\Settings" /v PausedQualityStatus /t REG_DWORD /d 1 /f > nul

set "_uxKey=HKLM\SOFTWARE\Microsoft\WindowsUpdate\UX\Settings"
reg add "%_uxKey%" /v FlightSettingsMaxPauseDays /t REG_DWORD /d 356000 /f > nul
reg add "%_uxKey%" /v PauseFeatureUpdatesStartTime /t REG_SZ /d "2001-10-25T10:03:37Z" /f > nul
reg add "%_uxKey%" /v PauseQualityUpdatesStartTime /t REG_SZ /d "2001-10-25T10:03:37Z" /f > nul
reg add "%_uxKey%" /v PauseUpdatesStartTime /t REG_SZ /d "2001-10-25T10:03:37Z" /f > nul
reg add "%_uxKey%" /v PauseFeatureUpdatesEndTime /t REG_SZ /d "3000-12-31T14:03:37Z" /f > nul
reg add "%_uxKey%" /v PauseQualityUpdatesEndTime /t REG_SZ /d "3000-12-31T14:03:37Z" /f > nul
reg add "%_uxKey%" /v PauseUpdatesExpiryTime /t REG_SZ /d "3000-12-31T14:03:37Z" /f > nul

reg add "%_uxKey%" /v HideMCTLink /t REG_DWORD /d 1 /f > nul
reg add "%_uxKey%" /v RestartNotificationsAllowed2 /t REG_DWORD /d 0 /f > nul
reg add "HKLM\SYSTEM\Setup\UpgradeNotification" /v UpgradeAvailable /t REG_DWORD /d 0 /f > nul

echo Done. Windows Updates have been paused.
if "%~1"=="/silent" exit /b
pause


