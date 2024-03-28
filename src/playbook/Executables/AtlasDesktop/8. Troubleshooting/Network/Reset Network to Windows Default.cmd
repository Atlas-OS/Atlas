@echo off

whoami /user | find /i "S-1-5-18" > nul 2>&1 || (
	call RunAsTI.cmd "%~f0" %*
	exit /b
)

echo Resetting network settings to Windows defaults...

(
	netsh int ip reset
	netsh interface ipv4 reset
	netsh interface ipv6 reset
	netsh interface tcp reset
	netsh winsock reset
) > nul

PowerShell -NoP -C "foreach ($dev in Get-PnpDevice -Class Net -Status 'OK') { pnputil /remove-device $dev.InstanceId }" > nul
pnputil /scan-devices > nul

echo Finished, please reboot your device for changes to apply.
pause
exit /b