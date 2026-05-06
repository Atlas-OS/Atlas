@echo off
:: Change to match the setting name (e.g., Sleep, Indexing, etc.)
set "settingName=Home"
:: Change to 0 (Disabled) or 1 (Enabled/Minimal) etc
set "stateValue=0"
set "scriptPath=%~f0"

set "scriptArgs=%*"
call "%windir%\AtlasModules\Scripts\prepareSetting.cmd" "%settingName%" "%stateValue%" "%scriptPath%" "%scriptArgs%"
if errorlevel 1 exit /b

:: End of state and path update

reg delete "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\Desktop\NameSpace\{f874310e-b6b7-47dc-bc84-b9e6b38f5903}" /f > nul 2>&1
reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" /v "LaunchTo" /t REG_DWORD /d "1" /f > nul

if "%~1" == "/justcontext" exit /b
if "%~1"=="/silent" exit /b

echo Changes applied successfully.
echo Press any key to exit...
pause > nul
exit /b
