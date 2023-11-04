<# : batch portion
@echo off
goto main

----------------------------------------------------------------------------
[USAGE]
call toggleDev.cmd [-Enable] [-Silent] [-Devices @("Device1", "Device2")] ...

You can use wildcards, like '*Device*'
If -Enable is not specified, device is disabled

[USAGE IN A SCRIPT]
- Made by he3als & Xyueta
- Below shows how to use it for mass disabling devices in a batch script

for %%a in (
	"ACPI Processor Aggregator"
	"*SmBus*"
) do (
	if defined devices (
		set "devices=%devices%, "%%~a""
	) else (
		set "devices=@("%%~a""
	)
)

set "devices=%devices%)"
call toggleDev.cmd %devices%

----------------------------------------------------------------------------

:main
fltmc > nul 2>&1 || (
	echo Administrator privileges are required.
	PowerShell Start -Verb RunAs '%0' 2> nul || (
		echo You must run this script as admin.
		exit /b 1
	)
	exit /b
)

set args= & set "args1=%*"
if defined args1 set "args=%args1:"='%"
powershell -noni -nop "& ([Scriptblock]::Create((Get-Content '%~f0' -Raw))) %args%"
exit /b %ERRORLEVEL%
: end batch / begin PowerShell #>

param (
    [switch]$Enable,
	[switch]$Silent,
	[string]$Devices
)

if ((($Devices -eq [array]) -and ($Devices.count -gt 0)) -or (!$Devices)) {
	throw "Devices not passed."
	exit 1
}

if (!($Enable)) {$State = 'Disabl'} else {$State = 'Enabl'}

try {
	$foundDevices = Get-PnpDevice -FriendlyName $devices -ErrorAction Ignore
} catch {
	Write-Host "`nSomething went wrong getting the devices! Error:" -ForegroundColor Red
	Write-Host "$_`n" -ForegroundColor Red
	exit 1
}

foreach ($device in $foundDevices) {
	try {
		$device | & $State`e-PnpDevice -Confirm:$false -ErrorAction Ignore
	} catch {
		Write-Host "`nSomething went wrong $State`ing the device: $device" -ForegroundColor Red
		Write-Host "$_`n" -ForegroundColor Red
	}
}

if (!($Silent)) {
	Write-Host "$State`ed the matched specified devices:" -ForegroundColor Yellow
	foreach ($device in $foundDevices.FriendlyName) {
		Write-Host " - " -NoNewLine -ForegroundColor Blue
		Write-Host "$device"
	}
}