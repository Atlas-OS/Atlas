@echo off

fltmc > nul 2>&1 || (echo You must run this script as admin. & exit /b)
if "%~1"=="" goto help
if "%~2"=="" goto help

set "___pageKey=HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\Explorer"
set ___silent=
set ___currentPages=

(for /f "usebackq tokens=3*" %%a in (`reg query "%___pageKey%" /v "SettingsPageVisibility"`) do (set "___currentPages=%%a%%b")) > nul 2>&1
if defined ___currentPages set "___currentPages=%___currentPages: =%"

if "%~3"=="/silent" set ___silent=true
if "%~1"=="/hide" call :hide "%~2"
if "%~1"=="/unhide" call :unhide "%~2"
exit /b


:help
    echo You must use one (not in combination):
    echo /hide [page] [/silent]
    echo /unhide [page] [/silent]
    exit /b


:hide
    if not defined ___silent echo Hiding Settings pages...
    if not defined ___currentPages (
        reg add "%___pageKey%" /v "SettingsPageVisibility" /t REG_SZ /d "hide:%~1" /f > nul
        exit /b
    )

    echo "%___currentPages%" | find "%~1" > nul && exit /b

    reg add "%___pageKey%" /v "SettingsPageVisibility" /t REG_SZ /d "%___currentPages%;%~1" /f > nul
    exit /b


:unhide
    if not defined ___silent echo Unhiding Settings pages...
    if not defined ___currentPages exit /b

    set "___page=%~1"
    call set "___newPages=%%___currentPages:%___page%=%%"
    reg add "%___pageKey%" /v "SettingsPageVisibility" /t REG_SZ /d "%___newPages%" /f > nul

    exit /b