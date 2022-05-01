@echo off
bcdedit /set {current} safeboot
bcdedit /set {current} safebootalternateshell yes
echo Finished, please reboot for changes to apply.
pause