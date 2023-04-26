@echo off
setlocal EnableDelayedExpansion

whoami /user | find /i "S-1-5-18" > nul 2>&1 || (
	call RunAsTI.cmd "%~f0" "%*"
	exit /b
)

:: Clean up temp folders
for %%a in (
    "!TEMP!"
    "!windir!\temp"
) do (
    rd /s /q %%a
    md %%a
)

:: Fix errors 2502 and 2503 by fixing temp folder permissions
for /f "tokens=*" %%a in ('whoami') do (set USER=%%a)
icacls "C:\Windows\Temp" /grant:r !USER!:(OI)(CI)F /grant:r Administrators:(OI)(CI)F /T /Q

:: Clean up the Prefetch folder
rd /s /q !windir!\Prefetch

:: Clear the icon cache
del /a /q "!LOCALAPPDATA!\IconCache.db"
del /a /f /q "!LOCALAPPDATA!\Microsoft\Windows\Explorer\iconcache*"

:: Clear all Event Viewer logs
for /f "tokens=*" %%a in ('wevtutil el') do (
    wevtutil cl "%%a"
)

:: Disable third party services for browsers updates
for %%a in (edgeupdate edgeupdatem gupdate gupdatem MozillaMaintenance) do (
    sc query "%%a"
    if !errorlevel! equ 0 (
        call setSvc.cmd %%a 4
    )
)

exit /b