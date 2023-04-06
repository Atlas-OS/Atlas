@echo off
goto main

:: Made by he3als

----------------------------------------------------------------------------
[USAGE IN A SCRIPT]
- Below shows how to use it for mass disabling devices in a script
- For more simple tasks, use: ToggleDevices.cmd [/e] "Device1" "Device2" ...
----------------------------------------------------------------------------

if defined EnableDelayedExpansion (set __noChange=true) else (setlocal EnabledDelayedExpansion)
set "__devices="

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

ToggleDevices.cmd %__devices%
if defined __noChange setlocal DisableDelayedExpansion

----------------------------------------------------------------------------

:main
fltmc > nul 2>&1 || (
	echo Administrator privileges are required, run this script as administrator.
	exit /b
)

set "__arguments=%*"
if not defined __arguments (
	echo]
	echo ToggleDevices.cmd [/e] "Device1" "Device2" ...
	echo]
	echo You can use wildcards, like '*Device*'
	echo If /e is not specified, device is disabled
	exit /b
)

if "%~1"=="/e" (set __state=enable) else (set __state=disable)

:: Remove /e from arguments
set __arguments=%__arguments:/e =%

call :dequote __arguments

:: Make a comma seperated
set __list=%__arguments:" "=,%

:: Disable/enable PnP device(s)
PowerShell -NonI -NoP $devices = """%__list%""" -split ""","""; Get-PnpDevice -FriendlyName $devices -ErrorAction Ignore ^| %__state%-PnpDevice -Confirm:$false -ErrorAction Ignore

echo Attempted to %__state% specified devices.
exit /b

:dequote
for /f "delims=" %%a in ('echo %%%1%%') do set %1=%%~a
exit /b