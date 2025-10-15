@echo off
setlocal EnableDelayedExpansion

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
:: Disable Spectre and Meltdown
reg add "HKLM\SYSTEM\CurrentControlSet\Control\Session Manager\Memory Management" /v "FeatureSettingsOverride" /t REG_DWORD /d "3" /f > nul
reg add "HKLM\SYSTEM\CurrentControlSet\Control\Session Manager\Memory Management" /v "FeatureSettingsOverrideMask" /t REG_DWORD /d "3" /f > nul

:: Disable Structured Exception Handling Overwrite Protection (SEHOP)
:: Exists in ntoskrnl strings, keep for now
reg add "HKLM\SYSTEM\CurrentControlSet\Control\Session Manager\kernel" /v "DisableExceptionChainValidation" /t REG_DWORD /d "1" /f > nul

:: Disable Control Flow Guard (CFG)
:: Find correct mitigation values for different Windows versions
:: Initialize bit mask in registry by disabling a random mitigation
PowerShell -NoP -C "Set-ProcessMitigation -System -Disable CFG" > nul

:: Get current bit mask
for /f "tokens=3 skip=2" %%a in ('reg query "HKLM\SYSTEM\CurrentControlSet\Control\Session Manager\kernel" /v "MitigationAuditOptions"') do (
    set "mitigation_mask=%%a"
)

:: Set all bits to 2 (Disable all process mitigations)
for /l %%a in (0,1,9) do (
    set "mitigation_mask=!mitigation_mask:%%a=2!"
)

:: Fix Valorant with mitigations disabled - enable CFG
set "enableCFGApps=valorant valorant-win64-shipping vgtray vgc"
PowerShell -NoP -C "foreach ($a in $($env:enableCFGApps -split ' ')) {Set-ProcessMitigation -Name $a`.exe -Enable CFG}" > nul

:: Set Data Execution Prevention (DEP) only for operating system components
:: https://docs.microsoft.com/en-us/windows/win32/memory/data-execution-prevention
:: https://learn.microsoft.com/en-us/windows-hardware/drivers/devtest/bcdedit--set#verification-settings
bcdedit /set nx OptIn > nul

:: Apply mask to kernel
reg add "HKLM\SYSTEM\CurrentControlSet\Control\Session Manager\kernel" /v "MitigationAuditOptions" /t REG_BINARY /d "%mitigation_mask%" /f > nul
reg add "HKLM\SYSTEM\CurrentControlSet\Control\Session Manager\kernel" /v "MitigationOptions" /t REG_BINARY /d "%mitigation_mask%" /f > nul

:: Disable file system mitigations
reg add "HKLM\SYSTEM\CurrentControlSet\Control\Session Manager" /v "ProtectionMode" /t REG_DWORD /d "0" /f > nul

if "%~1" == "/silent" exit /b

echo Finished, please reboot your device for changes to apply.
pause
exit /b
