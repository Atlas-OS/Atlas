@echo off
SetLocal EnableDelayedExpansion
echo Please wait. This may take a moment. DO NOT CLOSE THIS WINDOW
:start
set success=
C:\Windows\AtlasModules\nsudo -U:T -P:E -Wait C:\Windows\AtlasModules\atlas-config.bat /start
:: Read from success file
set /p success=<C:\Users\Public\success.txt
:: check if script finished
if %success% equ true goto success
:: if not, restart script
echo POST INSTALL SCRIPT CLOSED!
echo Relaunching...
goto start
:success
del /f /q "C:\Users\Public\success.txt"
shutdown /r /f /t 10 /c "Required Reboot"
DEL "%~f0"
exit