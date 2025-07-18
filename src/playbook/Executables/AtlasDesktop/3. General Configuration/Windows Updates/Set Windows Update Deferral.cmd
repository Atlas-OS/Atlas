@echo off
setlocal

set "settingNameFeature=FeatureUpdateDeferrals"
set "settingNameQuality=QualityUpdateDeferrals"
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

:main
:FeaturePrompt
set /p FeatureDeferral=Enter number of days to defer FEATURE updates (1-365): 
set /a _test=%FeatureDeferral% >nul 2>&1
if errorlevel 1 (
    echo Invalid input: %FeatureDeferral%. Please enter a whole number between 1 and 365.
    goto FeaturePrompt
)
if %FeatureDeferral% LSS 1 (
    echo Invalid input: %FeatureDeferral%. Please enter a number between 1 and 365.
    goto FeaturePrompt
)
if %FeatureDeferral% GTR 365 (
    echo Invalid input: %FeatureDeferral%. Please enter a number between 1 and 365.
    goto FeaturePrompt
)

:QualityPrompt
set /p QualityDeferral=Enter number of days to defer QUALITY updates (1-365): 
set /a _test=%QualityDeferral% >nul 2>&1
if errorlevel 1 (
    echo Invalid input: %QualityDeferral%. Please enter a whole number between 1 and 365.
    goto QualityPrompt
)
if %QualityDeferral% LSS 1 (
    echo Invalid input: %QualityDeferral%. Please enter a number between 1 and 365.
    goto QualityPrompt
)
if %QualityDeferral% GTR 365 (
    echo Invalid input: %QualityDeferral%. Please enter a number between 1 and 365.
    goto QualityPrompt
)

echo.
echo Applying Windows Update deferral settings...


reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate" /v DeferFeatureUpdates /t REG_DWORD /d 1 /f
reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate" /v DeferFeatureUpdatesPeriodInDays /t REG_DWORD /d %FeatureDeferral% /f

reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate" /v DeferQualityUpdates /t REG_DWORD /d 1 /f
reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate" /v DeferQualityUpdatesPeriodInDays /t REG_DWORD /d %QualityDeferral% /f

reg add "HKLM\SOFTWARE\AtlasOS\%settingNameFeature%" /v state /t REG_DWORD /d %stateValue% /f >nul
reg add "HKLM\SOFTWARE\AtlasOS\%settingNameFeature%" /v path /t REG_SZ /d "%scriptPath%" /f >nul
reg add "HKLM\SOFTWARE\AtlasOS\%settingNameFeature%" /v days /t REG_DWORD /d %FeatureDeferral% /f >nul

reg add "HKLM\SOFTWARE\AtlasOS\%settingNameQuality%" /v state /t REG_DWORD /d %stateValue% /f >nul
reg add "HKLM\SOFTWARE\AtlasOS\%settingNameQuality%" /v path /t REG_SZ /d "%scriptPath%" /f >nul
reg add "HKLM\SOFTWARE\AtlasOS\%settingNameQuality%" /v days /t REG_DWORD /d %QualityDeferral% /f >nul

echo.
echo Deferral settings applied successfully.
pause