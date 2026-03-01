@echo off
:: Change to match the setting name (e.g., Sleep, Indexing, etc.)
set "settingName=AutomaticFolderDiscovery"
:: Change to 0 (Disabled) or 1 (Enabled/Minimal) etc
set "stateValue=0"
set "scriptPath=%~f0"

set "scriptArgs=%*"
call "%windir%\AtlasModules\Scripts\prepareSetting.cmd" "%settingName%" "%stateValue%" "%scriptPath%" "%scriptArgs%"
if errorlevel 1 exit /b

:: End of state and path update
reg delete "HKCU\Software\Classes\Local Settings\Software\Microsoft\Windows\Shell\Bags" /f > nul 2>&1
reg add "HKCU\Software\Classes\Local Settings\Software\Microsoft\Windows\Shell\Bags\AllFolders\Shell" /v "FolderType" /t REG_SZ /d "NotSpecified" /f > nul

if "%~1" == "/justcontext" exit /b
if "%~1"=="/silent" exit /b

echo Changes applied successfully.
echo Press any key to exit...
pause > nul
exit /b
