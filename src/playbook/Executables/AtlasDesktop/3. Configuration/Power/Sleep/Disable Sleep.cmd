@echo off

:: Allow Away Mode Policy - No
powercfg /setacvalueindex scheme_current 238c9fa8-0aad-41ed-83f4-97be242c8f20 25dfa149-5dd1-4736-b5ab-e8a37b5b8187 0

:: Allow Standby States - Off
powercfg /setacvalueindex scheme_current 238c9fa8-0aad-41ed-83f4-97be242c8f20 abfc2519-3608-4c2a-94ea-171b0ed546ab 0

:: Allow hybrid sleep - Off
powercfg /setacvalueindex scheme_current 238c9fa8-0aad-41ed-83f4-97be242c8f20 94ac6d29-73ce-41a6-809f-6363ba21b47e 0

:: System unattended sleep timeout - 0 seconds
powercfg /setacvalueindex scheme_current 238c9fa8-0aad-41ed-83f4-97be242c8f20 7bc4a2f9-d8fc-4469-b07b-33eb785aaca0 0

:: Allow wake timers - Disable
powercfg /setacvalueindex scheme_current 238c9fa8-0aad-41ed-83f4-97be242c8f20 bd3b718a-0680-4d9d-8ab2-e1d2b4ac806d 0

:: Deep Sleep Enabled/Disabled - Deep Sleep Disabled
powercfg /setacvalueindex scheme_current 2e601130-5351-4d9d-8e04-252966bad054 d502f7ee-1dc7-4efd-a55d-f04b6f5c0545 0

:: Apply power scheme
powercfg /setactive scheme_current

if "%~1" == "/silent" exit /b

choice /n /c:yn /m "Would you like to disable hibernation? [Y/N]"
if %errorlevel%==1 (
	start "Disabling Hibernation" "%windir%\AtlasDesktop\3. Configuration\Power\Hibernation\Disable Hibernation (default).cmd"
) else (
	start "Enabling Hibernation" "%windir%\AtlasDesktop\3. Configuration\Power\Hibernation\Enable Hibernation.cmd"
)

echo Finished, changes have been applied.
pause
exit /b
