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

call setSvc.cmd KSecPkg 4
call setSvc.cmd LanmanServer 4
call setSvc.cmd LanmanWorkstation 4
call setSvc.cmd mrxsmb 4
call setSvc.cmd mrxsmb20 4
call setSvc.cmd rdbss 3
call setSvc.cmd srv2 4

DISM /Online /Disable-Feature /FeatureName:"SmbDirect" /NoRestart

echo]
echo Finished, please reboot your device for changes to apply.
pause
exit /b