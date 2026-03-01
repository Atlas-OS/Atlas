@echo off
:: Change to match the setting name (e.g., Sleep, Indexing, etc.)
set "settingName=OldContextMenu"
:: Change to 0 (Disabled) or 1 (Enabled/Minimal) etc
set "stateValue=0"
set "scriptPath=%~f0"

set "scriptArgs=%*"
call "%windir%\AtlasModules\Scripts\prepareSetting.cmd" "%settingName%" "%stateValue%" "%scriptPath%" "%scriptArgs%"
if errorlevel 1 exit /b

:: End of state and path update

reg add "HKCU\Software\Classes\CLSID\{86ca1aa0-34aa-4e8b-a509-50c905bae2a2}\InprocServer32" /d "" /f > nul

if "%~1" == "/justcontext" exit /b
if "%~1"=="/silent" exit /b

echo Changes applied successfully.
echo Press any key to exit...
pause > nul
exit /b
