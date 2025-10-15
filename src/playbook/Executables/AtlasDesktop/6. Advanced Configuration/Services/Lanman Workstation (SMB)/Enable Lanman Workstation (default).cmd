@echo off

if "%~1" == "/silent" goto main

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

:main
call setSvc.cmd KSecPkg 0
call setSvc.cmd LanmanServer 2
call setSvc.cmd LanmanWorkstation 2
call setSvc.cmd mrxsmb 3
call setSvc.cmd mrxsmb20 3
call setSvc.cmd rdbss 1
call setSvc.cmd srv2 3

DISM /Online /Enable-Feature /FeatureName:"SmbDirect" /NoRestart

if "%~1" == "/silent" exit /b

echo]
echo Finished, please reboot your device for changes to apply.
pause
exit /b