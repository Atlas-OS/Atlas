@echo off
setlocal EnableDelayedExpansion

if "%~1"=="/main" goto main

echo WARNING: This will force enable all security mitigiations for improved security.
echo          This will slow down performance, and worsen compatibility. It is
echo          recommended to use 'Set Windows Default Mitigations.cmd' instead.
echo]
timeout /t 3 /nobreak > nul
echo Press any key to continue anyways...
pause > nul
cls

whoami /user | find /i "S-1-5-18" > nul 2>&1 || (
	call RunAsTI.cmd "%~f0" "/main"
	exit /b
)

:main
:: Enable Spectre and Meltdown
reg add "HKLM\SYSTEM\CurrentControlSet\Control\Session Manager\Memory Management" /v "FeatureSettingsOverrideMask" /t REG_DWORD /d "3" /f > nul
powershell -NonI -NoP -C "$proc = (Get-CimInstance Win32_Processor).Name; $env:CPU = if ($proc | sls 'Intel' -Quiet) {'0'} elseif ($proc | sls 'AMD' -Quiet) {'64'}"
if "%CPU%" neq "" (
    reg add "HKLM\SYSTEM\CurrentControlSet\Control\Session Manager\Memory Management" /v "FeatureSettingsOverride" /t REG_DWORD /d "%CPU%" /f > nul
) 

:: Enable Structured Exception Handling Overwrite Protection (SEHOP)
reg add "HKLM\SYSTEM\CurrentControlSet\Control\Session Manager\kernel" /v "DisableExceptionChainValidation" /t REG_DWORD /d "0" /f > nul

:: Enable Control Flow Guard (CFG)
PowerShell -NoP -C "Set-ProcessMitigation -System -Enable CFG"

:: Get current bit mask
for /f "tokens=3 skip=2" %%a in ('reg query "HKLM\SYSTEM\CurrentControlSet\Control\Session Manager\kernel" /v "MitigationAuditOptions"') do (
    set "mitigation_mask=%%a"
)

:: Set all bits to 1 (enable all mitigations)
for /l %%a in (0,1,9) do (
    set "mitigation_mask=!mitigation_mask:%%a=1!"
)

:: Apply mask to kernel
reg add "HKLM\SYSTEM\CurrentControlSet\Control\Session Manager\kernel" /v "MitigationAuditOptions" /t REG_BINARY /d "%mitigation_mask%" /f > nul
reg add "HKLM\SYSTEM\CurrentControlSet\Control\Session Manager\kernel" /v "MitigationOptions" /t REG_BINARY /d "%mitigation_mask%" /f > nul

:: Enable Data Execution Prevention (DEP) always
:: https://docs.microsoft.com/en-us/windows/win32/memory/data-execution-prevention
bcdedit /set nx AlwaysOn > nul

:: Enable file system mitigations
reg add "HKLM\SYSTEM\CurrentControlSet\Control\Session Manager" /v "ProtectionMode" /t REG_DWORD /d "1" /f > nul

:: Enable for Hyper-V
reg add "HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Virtualization" /v "MinVmVersionForCpuBasedMitigations" /t REG_SZ /d "1.0" /f > nul

echo Finished, please reboot your device for changes to apply.
pause
exit /b