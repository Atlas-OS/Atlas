@echo off
pushd "%~dp0"
echo Building Playbook...
powershell -nop -ep bypass ^& "%cd%\..\dependencies\local-build.ps1" -AddLiveLog -ReplaceOldPlaybook -Removals WinverRequirement, Verification -DontOpenPbLocation
if %errorlevel% neq 0 (
    if "%*"=="" pause
)
popd