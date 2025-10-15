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

:: Enable Spectre and Meltdown
reg delete "HKLM\SYSTEM\CurrentControlSet\Control\Session Manager\Memory Management" /v "FeatureSettingsOverride" /f > nul 2>&1
reg delete "HKLM\SYSTEM\CurrentControlSet\Control\Session Manager\Memory Management" /v "FeatureSettingsOverrideMask" /f > nul 2>&1

:: Enable Structured Exception Handling Overwrite Protection (SEHOP)
reg delete "HKLM\SYSTEM\CurrentControlSet\Control\Session Manager\kernel" /v "DisableExceptionChainValidation" /f > nul 2>&1

:: Set default mitigations
reg delete "HKLM\SYSTEM\CurrentControlSet\Control\Session Manager\kernel" /v "MitigationAuditOptions" /f > nul 2>&1
reg delete "HKLM\SYSTEM\CurrentControlSet\Control\Session Manager\kernel" /v "MitigationOptions" /f > nul 2>&1

:: Set Data Execution Prevention (DEP) only for operating system components
:: https://docs.microsoft.com/en-us/windows/win32/memory/data-execution-prevention
:: https://learn.microsoft.com/en-us/windows-hardware/drivers/devtest/bcdedit--set#verification-settings
bcdedit /set nx OptIn > nul

:: Enable file system mitigations
reg add "HKLM\SYSTEM\CurrentControlSet\Control\Session Manager" /v "ProtectionMode" /t REG_DWORD /d "1" /f > nul

:: Default Hyper-V Settings
reg delete "HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Virtualization" /v "MinVmVersionForCpuBasedMitigations" /f > nul 2>&1

echo Finished, please reboot your device for changes to apply.
pause
exit /b
