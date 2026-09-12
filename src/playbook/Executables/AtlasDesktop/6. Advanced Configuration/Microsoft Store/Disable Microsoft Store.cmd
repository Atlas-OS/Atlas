@echo off
set "settingName=MicrosoftStore"
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

if not "%~1"=="/silent" call "%windir%\AtlasModules\Scripts\serviceWarning.cmd" %*

reg add "HKLM\SOFTWARE\AtlasOS\Services\%settingName%" /v state /t REG_DWORD /d %stateValue% /f > nul
reg add "HKLM\SOFTWARE\AtlasOS\Services\%settingName%" /v path  /t REG_SZ    /d "%scriptPath%" /f > nul

powershell -NoP -NonI -Command "Get-AppxPackage -AllUsers Microsoft.WindowsStore | Remove-AppxPackage" > nul

if "%~1"=="/silent" exit /b

echo.
echo Microsoft Store has been removed.
echo You can restore it later with the enable script.
echo Press any key to exit...
pause > nul
exit /b 