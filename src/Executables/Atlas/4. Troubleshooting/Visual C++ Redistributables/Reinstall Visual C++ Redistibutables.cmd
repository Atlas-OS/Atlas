@echo off
setlocal EnableDelayedExpansion

whoami /user | find /i "S-1-5-18" > nul 2>&1 || (
	call RunAsTI.cmd "%~f0" "%*"
	exit /b
)

:: Set the current hash
for /f "delims=" %%a in ('certutil -hashfile "!windir!\AtlasModules\Apps\VisualCppRedist_AIO_x86_x64.exe" SHA256 ^| findstr /V ":"') do (
	set "oldHash=%%a"
	set "oldHash=!oldHash: =!"
)

:: Set the latest hash
for /f "delims=" %%a in ('PowerShell "(Invoke-RestMethod -Uri "https://api.github.com/repos/abbodi1406/vcredist/releases/latest").body" ^| findstr SHA-256') do (
	set "newHash=%%a"
	set "newHash=!newHash:SHA-256: =!"
	goto main
)

:main
:: Compare old hash and new hash
if not "!oldHash!" == "!newHash!" (
    echo Downloading latest version of Visual C++ Redistibutables...
	for /f "delims=" %%a in ('PowerShell "(Invoke-RestMethod -Uri "https://api.github.com/repos/abbodi1406/vcredist/releases/latest").assets.browser_download_url"') do (
		PowerShell -NoP -C "Invoke-WebRequest -Uri %%a -OutFile !TEMP!\VC++.zip"
		PowerShell -NoP -C "Expand-Archive -Path '!TEMP!\VC++.zip' -DestinationPath '!TEMP!\VC++'"
		move /y !TEMP!\VC++\VisualCppRedist_AIO_x86_x64.exe !windir!\AtlasModules\Apps
		del /q "!TEMP!\*" > nul 2>&1 && for /d %%a in ("!TEMP!\*.*") do rmdir "%%a" /s /q > nul 2>&1 && cls
	)
)

echo Removing previous installations of Visual C++ Redistibutables...
VisualCppRedist_AIO_x86_x64.exe /aiR

echo Installing Visual C++ Redistibutables...
VisualCppRedist_AIO_x86_x64.exe /ai

echo Finished, please reboot your device for changes to apply.
pause
exit /b
