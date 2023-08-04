@echo off
setlocal EnableDelayedExpansion

for /f "usebackq delims=" %%a in (`dir /b /a:d "!SystemDrive!\Users" ^| findstr /v /i /x /c:"Public" /c:"Default User" /c:"All Users"`) do (
	set "atlasFolderPath=!SystemDrive!\Users\%%a\Desktop\Atlas"
	robocopy "Atlas" "%atlasFolderPath%" /E /PURGE /IM /IT /NP
	rem Prevent people from removing the Atlas folder
	takeown /f "%atlasFolderPath%" /r /d y > nul
	icacls "%atlasFolderPath%" /reset > nul
	icacls "%atlasFolderPath%" /inheritance:r > nul
	icacls "%atlasFolderPath%" /grant:r "SYSTEM:(OI)(CI)F" /grant:r "Users:(OI)(CI)RX" /grant:r "Administrators:(OI)(CI)RX" /t > nul
)