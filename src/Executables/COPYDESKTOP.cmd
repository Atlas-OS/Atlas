@echo off
setlocal EnableDelayedExpansion

for /f "usebackq delims=" %%a in (`dir /b /a:d "!SystemDrive!\Users" ^| findstr /v /i /x /c:"Public" /c:"Default User" /c:"All Users"`) do (
	echo robocopy "REFINEDOS" "!SystemDrive!\Users\%%a\Desktop\REFINEDOS" /e /purge /im /it /np
	robocopy "REFINEDOS" "!SystemDrive!\Users\%%a\Desktop\REFINEDOS" /e /purge /im /it /np
)
