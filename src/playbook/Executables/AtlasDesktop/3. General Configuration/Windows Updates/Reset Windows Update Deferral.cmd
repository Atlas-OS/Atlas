@echo off
setlocal

set "settingNameFeature=FeatureUpdateDeferrals"
set "settingNameQuality=QualityUpdateDeferrals"
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
reg add "HKLM\SOFTWARE\AtlasOS\Services%settingNameFeature%" /v state /t REG_DWORD /d %stateValue% /f >nul
reg add "HKLM\SOFTWARE\AtlasOS\Services%settingNameFeature%" /v path /t REG_SZ /d "%scriptPath%" /f >nul
reg add "HKLM\SOFTWARE\AtlasOS\Services%settingNameFeature%" /v days /t REG_DWORD /d 0 /f >nul

reg add "HKLM\SOFTWARE\AtlasOS\Services%settingNameQuality%" /v state /t REG_DWORD /d %stateValue% /f >nul
reg add "HKLM\SOFTWARE\AtlasOS\Services%settingNameQuality%" /v path /t REG_SZ /d "%scriptPath%" /f >nul
reg add "HKLM\SOFTWARE\AtlasOS\Services%settingNameQuality%" /v days /t REG_DWORD /d 0 /f >nul

echo Resetting Windows Update deferral policies...

reg delete "HKLM\SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate" /v DeferFeatureUpdates /f >nul 2>&1
reg delete "HKLM\SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate" /v DeferFeatureUpdatesPeriodInDays /f >nul 2>&1
reg delete "HKLM\SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate" /v DeferQualityUpdates /f >nul 2>&1
reg delete "HKLM\SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate" /v DeferQualityUpdatesPeriodInDays /f >nul 2>&1

echo Done. Windows Update deferrals have been reset to default.
pause
