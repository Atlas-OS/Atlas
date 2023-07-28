@echo off
setlocal EnableDelayedExpansion

whoami /user | find /i "S-1-5-18" > nul 2>&1 || (
	call RunAsTI.cmd "%~f0" "%*"
	exit /b
)

netsh int ip reset
netsh winsock reset

PowerShell -NoP -C "foreach ($dev in Get-PnpDevice -Class Net -Status 'OK') {pnputil /remove-device $dev.InstanceId | Out-Null }; pnputil /scan-devices | Out-Null"

echo Finished, please reboot your device for changes to apply.
pause
exit /b