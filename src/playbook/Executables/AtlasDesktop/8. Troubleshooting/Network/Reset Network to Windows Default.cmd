@echo off

set "___args="%~f0" %*"
fltmc > nul 2>&1 || (
	echo Administrator privileges are required.
	powershell -c "Start-Process -Verb RunAs -FilePath 'cmd' -ArgumentList """/c $env:___args"""" 2> nul || (
		echo You must run this script as admin.
		if "%*"=="" pause
		exit /b 1
	)
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