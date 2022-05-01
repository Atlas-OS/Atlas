@echo off
bcdedit /deletevalue {current} safeboot
echo Finished, please reboot for changes to apply.
pause