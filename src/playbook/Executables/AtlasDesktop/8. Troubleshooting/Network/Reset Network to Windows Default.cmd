@echo off

whoami /user | find /i "S-1-5-18" > nul 2>&1 || (
	call RunAsTI.cmd "%~f0" %*
	exit /b
)

echo Applying changes...

netsh int ip reset > nul
netsh winsock reset > nul

PowerShell -NoP -C "foreach ($dev in Get-PnpDevice -Class Net -Status 'OK') {pnputil /remove-device $dev.InstanceId | Out-Null }; pnputil /scan-devices | Out-Null"

echo Finished, please reboot your device for changes to apply.
pause
exit /b