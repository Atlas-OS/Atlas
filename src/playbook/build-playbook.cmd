@echo off
pushd "%~dp0"
echo Building Playbook...

REM Self-contained build (no ..\dependencies\local-build.ps1 required).
REM Build-Playbook.ps1 regenerates playbook.ico, validates inputs,
REM and zips the playbook into "EBOS Release.apbx".
powershell -nop -ep bypass -File "%~dp0Build-Playbook.ps1" -FileName "EBOS Release"
if %errorlevel% neq 0 (
    if "%*"=="" pause
)

popd