@echo off
setlocal EnableDelayedExpansion

whoami /user | find /i "S-1-5-18" > nul 2>&1 || (
	call RunAsTI.cmd "%~f0" "%*"
	exit /b
)

:: Enable Spectre and Meltdown
reg delete "HKLM\SYSTEM\CurrentControlSet\Control\Session Manager\Memory Management" /v "FeatureSettingsOverride" /f > nul 2>&1
reg delete "HKLM\SYSTEM\CurrentControlSet\Control\Session Manager\Memory Management" /v "FeatureSettingsOverrideMask" /f > nul 2>&1

:: Rename Spectre and Meltdown updates
ren !windir!\System32\mcupdate_GenuineIntel.old mcupdate_GenuineIntel.dll > nul 2>&1
ren !windir!\System32\mcupdate_AuthenticAMD.old mcupdate_AuthenticAMD.dll > nul 2>&1

:: Enable Fault Tolerant Heap (FTH)
:: https://docs.microsoft.com/en-us/windows/win32/win7appqual/fault-tolerant-heap
:: Document listed as only affected in Windows 7, is also in 7+
reg add "HKLM\SOFTWARE\Microsoft\FTH" /v "Enabled" /t REG_DWORD /d "1" /f > nul

:: Enable Structured Exception Handling Overwrite Protection (SEHOP)
reg delete "HKLM\SYSTEM\CurrentControlSet\Control\Session Manager\kernel" /v "DisableExceptionChainValidation" /f > nul 2>&1

:: Set default mitigations
reg delete "HKLM\SYSTEM\CurrentControlSet\Control\Session Manager\kernel" /v "MitigationAuditOptions" /f > nul 2>&1
reg delete "HKLM\SYSTEM\CurrentControlSet\Control\Session Manager\kernel" /v "MitigationOptions" /f > nul 2>&1

:: Set Virtualization Based Protection Of Code Integrity to default
:: https://docs.microsoft.com/en-us/windows/security/threat-protection/device-guard/enable-virtualization-based-protection-of-code-integrity
reg delete "HKLM\SYSTEM\CurrentControlSet\Control\DeviceGuard\Scenarios\HypervisorEnforcedCodeIntegrity" /v "Enabled" /f > nul 2>&1

:: Enable Data Execution Prevention (DEP) for system components only
:: https://docs.microsoft.com/en-us/windows/win32/memory/data-execution-prevention
:: https://learn.microsoft.com/en-us/windows-hardware/drivers/devtest/bcdedit--set
bcdedit /set nx OptIn > nul

:: Enable file system mitigations
reg add "HKLM\SYSTEM\CurrentControlSet\Control\Session Manager" /v "ProtectionMode" /t REG_DWORD /d "1" /f > nul

:: Default Hyper-V Settings
reg delete "HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Virtualization" /v "MinVmVersionForCpuBasedMitigations" /f > nul 2>&1

echo Finished, please reboot your device for changes to apply.
pause
exit /b
