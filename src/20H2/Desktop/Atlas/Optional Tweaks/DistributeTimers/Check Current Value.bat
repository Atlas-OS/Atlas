@echo off
setlocal
for /f "tokens=2*" %%a in ('reg query "HKEY_LOCAL_MACHINE\System\CurrentControlSet\Control\Session Manager\kernel" /v "DistributeTimers"') do set "dt=%%b"
echo Current DistributeTimers Value: %dt%
pause