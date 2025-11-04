@echo off
setlocal

set "settingName=PauseUpdates"
set "stateValue=0"
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

:main
reg add "HKLM\SOFTWARE\AtlasOS\Services\%settingName%" /v state /t REG_DWORD /d %stateValue% /f >nul
reg add "HKLM\SOFTWARE\AtlasOS\Services\%settingName%" /v path /t REG_SZ /d "%scriptPath%" /f >nul
reg add "HKLM\SOFTWARE\AtlasOS\Services\%settingName%" /v days /t REG_DWORD /d 0 /f >nul

echo Resetting Windows Update pause policies...

reg delete "HKLM\SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate" /v DeferFeatureUpdates /f >nul 2>&1
reg delete "HKLM\SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate" /v DeferFeatureUpdatesPeriodInDays /f >nul 2>&1
reg delete "HKLM\SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate" /v DeferQualityUpdates /f >nul 2>&1
reg delete "HKLM\SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate" /v DeferQualityUpdatesPeriodInDays /f >nul 2>&1

for %%K in (Feature Quality) do (
    reg delete "HKLM\SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate" /v Pause%%KUpdates /f > nul 2>&1
    reg delete "HKLM\SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate" /v Pause%%KUpdatesStartTime /f > nul 2>&1
)

reg add "HKLM\SOFTWARE\Microsoft\WindowsUpdate\UpdatePolicy\Settings" /v PausedFeatureStatus /t REG_DWORD /d 0 /f > nul
reg add "HKLM\SOFTWARE\Microsoft\WindowsUpdate\UpdatePolicy\Settings" /v PausedQualityStatus /t REG_DWORD /d 0 /f > nul

set "_uxKey=HKLM\SOFTWARE\Microsoft\WindowsUpdate\UX\Settings"
reg delete "%_uxKey%" /v PauseFeatureUpdatesStartTime /f > nul 2>&1
reg delete "%_uxKey%" /v PauseFeatureUpdatesEndTime /f > nul 2>&1
reg delete "%_uxKey%" /v PauseQualityUpdatesStartTime /f > nul 2>&1
reg delete "%_uxKey%" /v PauseQualityUpdatesEndTime /f > nul 2>&1
reg delete "%_uxKey%" /v PauseUpdatesStartTime /f > nul 2>&1
reg delete "%_uxKey%" /v PauseUpdatesExpiryTime /f > nul 2>&1
reg delete "%_uxKey%" /v PausedFeatureStatus /f > nul 2>&1
reg delete "%_uxKey%" /v PausedQualityStatus /f > nul 2>&1
reg delete "%_uxKey%" /v FlightSettingsMaxPauseDays /f > nul 2>&1

reg delete "%_uxKey%" /v HideMCTLink /f > nul 2>&1
reg delete "%_uxKey%" /v RestartNotificationsAllowed2 /f > nul 2>&1
reg delete "HKLM\SYSTEM\Setup\UpgradeNotification" /v UpgradeAvailable /f > nul 2>&1

echo Done. Updates have been unpaused.
if "%~1"=="/silent" exit /b
pause
