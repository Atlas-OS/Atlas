@echo off
set "settingName=Widgets"
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

reg add "HKLM\SOFTWARE\AtlasOS\Services\%settingName%" /v state /t REG_DWORD /d %stateValue% /f > nul
reg add "HKLM\SOFTWARE\AtlasOS\Services\%settingName%" /v path /t REG_SZ /d "%scriptPath%" /f > nul

echo]
echo Disabling News and Interests (called Widgets in Windows 11)...

(
    reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows\Windows Feeds" /v "EnableFeeds" /t REG_DWORD /d "0" /f
    reg add "HKLM\SOFTWARE\Policies\Microsoft\Dsh" /v "AllowNewsAndInterests" /t REG_DWORD /d "0" /f
    if /I not "%~2"=="/noAction" powershell -command "stop-process -name explorer -force"
) > nul 2>&1
if "%~1"=="/silent" exit /b

echo]
echo Finished, changes have been applied.
echo Press any key to exit...
pause > nul
exit /b
