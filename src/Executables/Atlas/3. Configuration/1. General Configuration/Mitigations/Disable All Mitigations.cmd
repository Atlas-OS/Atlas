@echo off
setlocal EnableDelayedExpansion

if "%~1" == "/silent" goto main

whoami /user | find /i "S-1-5-18" > nul 2>&1 || (
	call RunAsTI.cmd "%~f0" "%*"
	exit /b
)

:main
:: Disable Spectre and Meltdown
reg add "HKLM\SYSTEM\CurrentControlSet\Control\Session Manager\Memory Management" /v "FeatureSettingsOverride" /t REG_DWORD /d "3" /f > nul
reg add "HKLM\SYSTEM\CurrentControlSet\Control\Session Manager\Memory Management" /v "FeatureSettingsOverrideMask" /t REG_DWORD /d "3" /f > nul

:: Rename Spectre and Meltdown updates
ren !windir!\System32\mcupdate_GenuineIntel.dll mcupdate_GenuineIntel.old
ren !windir!\System32\mcupdate_AuthenticAMD.dll mcupdate_AuthenticAMD.old

:: Disable Fault Tolerant Heap (FTH)
:: https://docs.microsoft.com/en-us/windows/win32/win7appqual/fault-tolerant-heap
:: Document listed as only affected in Windows 7, is also in 7+
reg add "HKLM\SOFTWARE\Microsoft\FTH" /v "Enabled" /t REG_DWORD /d "0" /f > nul

:: Disable Structured Exception Handling Overwrite Protection (SEHOP)
:: Exists in ntoskrnl strings, keep for now
reg add "HKLM\SYSTEM\CurrentControlSet\Control\Session Manager\kernel" /v "DisableExceptionChainValidation" /t REG_DWORD /d "1" /f > nul

:: Disable Control Flow Guard (CFG)
:: Find correct mitigation values for different Windows versions - AMIT
:: Initialize bit mask in registry by disabling a random mitigation
PowerShell -NoP -C "Set-ProcessMitigation -System -Disable CFG" > nul

:: Get current bit mask
for /f "tokens=3 skip=2" %%a in ('reg query "HKLM\SYSTEM\CurrentControlSet\Control\Session Manager\kernel" /v "MitigationAuditOptions"') do (
    set "mitigation_mask=%%a"
)

:: Set all bits to 2 (Disable all process mitigations)
for /l %%a in (0,1,9) do (
    set "mitigation_mask=!mitigation_mask:%%a=2!""
)

:: Fix Valorant with mitigations disabled - enable CFG
for %%a in (valorant valorant-win64-shipping vgtray vgc) do (
    PowerShell -NoP -C "Set-ProcessMitigation -Name %%a.exe -Enable CFG" > nul
)

:: Apply mask to kernel
reg add "HKLM\SYSTEM\CurrentControlSet\Control\Session Manager\kernel" /v "MitigationAuditOptions" /t REG_BINARY /d "!mitigation_mask!" /f > nul
reg add "HKLM\SYSTEM\CurrentControlSet\Control\Session Manager\kernel" /v "MitigationOptions" /t REG_BINARY /d "!mitigation_mask!" /f > nul

:: Disable virtualization-based protection of code integrity
:: https://docs.microsoft.com/en-us/windows/security/threat-protection/device-guard/enable-virtualization-based-protection-of-code-integrity
reg add "HKLM\SYSTEM\CurrentControlSet\Control\DeviceGuard\Scenarios\HypervisorEnforcedCodeIntegrity" /v "Enabled" /t REG_DWORD /d "0" /f > nul

:: Disable Data Execution Prevention (DEP)
:: It may be needed to enable it for FACEIT, Valorant and other anti-cheats
:: https://docs.microsoft.com/en-us/windows/win32/memory/data-execution-prevention
PowerShell -NoP -C "Set-ProcessMitigation -System -Disable DEP, EmulateAtlThunks"
bcdedit /set nx AlwaysOff > nul

:: Disable file system mitigations
reg add "HKLM\SYSTEM\CurrentControlSet\Control\Session Manager" /v "ProtectionMode" /t REG_DWORD /d "0" /f > nul

if "%~1" == "/silent" exit /b

echo Finished, please reboot your device for changes to apply.
pause
exit /b