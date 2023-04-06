@echo off
goto main

:: made by he3als

----------------------------------------------------------------------------
[USAGE IN A SCRIPT]
----------------------------------------------------------------------------

if defined enabledelayedexpansion (set __noChange=true) else (setlocal enabledelayedexpansion)
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
if defined __noChange setlocal disabledelayedexpansion

----------------------------------------------------------------------------

:main
fltmc >nul 2>&1 || (
	echo Administrator privileges are required, run this script as administrator.
	exit /b 1
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

:: remove /e from arguments
set __arguments=%__arguments:/e =%

call :dequote __arguments

:: make comma seperated
set __list=%__arguments:" "=,%

:: disable/enable pnp device(s)
powershell -noni -nop $devices = """%__list%""" -split ""","""; Get-PnpDevice -FriendlyName $devices -ErrorAction Ignore ^| %__state%-PnpDevice -Confirm:$false -ErrorAction Ignore

echo Attempted to %__state% specified devices.
exit /b

:dequote
for /f "delims=" %%a in ('echo %%%1%%') do set %1=%%~a
exit /b