@echo off
setlocal EnableDelayedExpansion

for /f "usebackq delims=" %%a in (`dir /b /a:d "!SystemDrive!\Users" ^| findstr /v /i /x /c:"Public" /c:"Default User" /c:"All Users"`) do (
	echo robocopy "Atlas" "!SystemDrive!\Users\%%a\Desktop\Atlas" /e /purge /im /it /np
	robocopy "Atlas" "!SystemDrive!\Users\%%a\Desktop\Atlas" /e /purge /im /it /np
)
