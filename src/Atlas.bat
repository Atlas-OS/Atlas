@echo off
SETLOCAL EnableDelayedExpansion
echo Please wait. This may take a moment. DO NOT CLOSE THIS WINDOW!

:start
set success=
C:\Windows\AtlasModules\NSudo.exe -U:T -P:E -Wait C:\Windows\AtlasModules\atlas-config.bat /start

:: read from success file
set /p success= < C:\Users\Public\success.txt

:: check if script is finished
if %success% equ true goto success

:: if not, restart script
echo POST INSTALL SCRIPT CLOSED!
echo Relaunching...
goto start

:success
del /f /q "C:\Users\Public\success.txt"
shutdown /r /f /t 10 /c "POST-INSTALL: Reboot is required..."
DEL "%~f0"
exit