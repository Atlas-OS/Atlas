@echo off
:: Change to match the setting name (e.g., Sleep, Indexing, etc.)
set "settingName=LanmanWorkstation"
:: Change to 0 (Disabled) or 1 (Enabled/Minimal) etc
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

:: Update Registry (State and Path)
reg add "HKLM\SOFTWARE\AtlasOS\%settingName%" /v state /t REG_DWORD /d %stateValue% /f > nul
reg add "HKLM\SOFTWARE\AtlasOS\%settingName%" /v path /t REG_SZ /d "%scriptPath%" /f > nul

if not "%~1"=="/silent" call "%windir%\AtlasModules\Scripts\serviceWarning.cmd" %*

call setSvc.cmd KSecPkg 4
call setSvc.cmd LanmanServer 4
call setSvc.cmd LanmanWorkstation 4
call setSvc.cmd mrxsmb 4
call setSvc.cmd mrxsmb20 4
call setSvc.cmd rdbss 3
call setSvc.cmd srv2 4

DISM /Online /Disable-Feature /FeatureName:"SmbDirect" /NoRestart

echo]
echo Finished, please reboot your device for changes to apply.
pause
exit /b