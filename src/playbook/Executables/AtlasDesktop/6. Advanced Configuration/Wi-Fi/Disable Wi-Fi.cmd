@echo off

whoami /user | find /i "S-1-5-18" > nul 2>&1 || (
	call RunAsTI.cmd "%~f0" %*
	exit /b
)

call setSvc.cmd vwififlt 4
call setSvc.cmd WlanSvc 4

echo Applications like Microsoft Store and Spotify may not function correctly when Wi-Fi is disabled.
echo There might be other issues as well, therefore, we do not recommend it.
pause
echo]
echo Finished, please reboot your device for changes to apply.
pause
exit /b