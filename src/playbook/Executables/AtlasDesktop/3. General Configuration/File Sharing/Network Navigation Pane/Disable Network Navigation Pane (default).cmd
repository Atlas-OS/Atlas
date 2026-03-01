@echo off
set "settingName=NetworkNavigationPane"
set "stateValue=0"
set "scriptPath=%~f0"

set "scriptArgs=%*"
call "%windir%\AtlasModules\Scripts\prepareSetting.cmd" "%settingName%" "%stateValue%" "%scriptPath%" "%scriptArgs%"
if errorlevel 1 exit /b


reg add "HKCU\SOFTWARE\Classes\CLSID\{F02C1A0D-BE21-4350-88B0-7367FC96EF3C}" /v "System.IsPinnedToNameSpaceTree" /t REG_DWORD /d 0 /f > nul

if "%~1" == "/justcontext" exit /b
if "%~1"=="/silent" exit /b

echo Finished, Network Navigation Pane is now disabled.
pause > nul
exit /b
