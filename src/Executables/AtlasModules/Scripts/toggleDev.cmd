@echo off
setlocal EnableDelayedExpansion

:: Detect whether the script is run with cmd or the external script
if not defined run_by (
	set "cmdcmdline=!cmdcmdline:"=!" 
	set "cmdcmdline=!cmdcmdline:~0,-1!"
	if /i "!cmdcmdline!" == "C:\Windows\System32\cmd.exe" (
        set "run_by=cmd"
	) else (
		set "run_by=external"
	)
)

whoami /user | find /i "S-1-5-18" > nul 2>&1 || (
	call RunAsTI.cmd "%~f0" "%*"
	if "!run_by!" == "cmd" (exit) else (exit /b)
)
goto main

----------------------------------------------------------------------------
[USAGE IN A SCRIPT]
- Made by he3als & Xyueta
- Below shows how to use it for mass disabling devices in a script
- For more simple tasks, use: call toggleDev.cmd [/e] "Device1" "Device2" ...
----------------------------------------------------------------------------

setlocal EnableDelayedExpansion
for %%a in (
	"ACPI Processor Aggregator"
	"*SmBus*"
) do (
	if defined __devices (
		set "__devices=!__devices! "%%~a""
	) else (
		set "__devices="%%~a""
	)
)

call toggleDev.cmd !__devices!

----------------------------------------------------------------------------

:main
set "__arguments=%*"
if not defined __arguments (
	echo toggleDev.cmd [/e] "Device1" "Device2" ...
	echo]
	echo You can use wildcards, like '*Device*'
	echo If /e is not specified, device is disabled
	echo]
	if "!run_by!" == "cmd" (pause & exit) else (exit /b)
)

if "%~1"=="/e" (set __state=enable) else (set __state=disable)

:: Remove /e from arguments
set __arguments=!__arguments:/e =!

call :dequote __arguments

:: Make a comma seperated
set __list=!__arguments:" "=,!

:: Disable/enable PnP device(s)
PowerShell -NonI -NoP $devices = """!__list!""" -split ""","""; Get-PnpDevice -FriendlyName $devices -ErrorAction Ignore ^| !__state!-PnpDevice -Confirm:$false -ErrorAction Ignore

echo Attempted to !__state! specified devices.
if "!run_by!" == "cmd" (pause & exit) else (exit /b)

:dequote
for /f "delims=" %%a in ('echo %%%1%%') do set %1=%%~a
exit /b