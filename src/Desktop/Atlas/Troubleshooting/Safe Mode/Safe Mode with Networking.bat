@echo off
bcdedit /set {current} safeboot network
echo Finished, please reboot for changes to apply.
pause