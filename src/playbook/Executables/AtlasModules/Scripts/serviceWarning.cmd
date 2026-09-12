@echo off
goto main

----------------------------------------

[FEATURES]
- Reusable warning for the user if a script modifies services and notifies of possible breakage.

[USAGE]
call serviceWarning.cmd [optional:specific comment for service breakage, use quotes]

----------------------------------------

:main
echo ------------------------------------------------------
echo WARNING: This script will modify system services.
echo Modifying services can lead to potential breakage of features and bugs.
echo Proceed with caution, and refer to Atlas docs for more information!
if not "%~1"=="" echo Specific Note: %~1
echo ------------------------------------------------------
pause