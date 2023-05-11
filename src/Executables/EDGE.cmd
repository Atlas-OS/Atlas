@echo off
setlocal EnableDelayedExpansion

for /f "usebackq tokens=2 delims=\" %%a in (`reg query "HKEY_USERS" ^| findstr /r /x /c:"HKEY_USERS\\S-.*" /c:"HKEY_USERS\\AME_UserHive_[^_]*"`) do (
	reg query "HKU\%%a" | findstr /c:"Volatile Environment" /c:"AME_UserHive_"
	if not !errorlevel! == 1 (
		for /f "usebackq tokens=2* delims= " %%c in (`reg query "HKU\%~1\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\Shell Folders" /v "AppData" ^| findstr /r /x /c:".*AppData[ ]*REG_SZ[ ].*"`) do (
			del "%%c\Microsoft\Internet Explorer\Quick Launch\Microsoft Edge.lnk" /q /f
			del "%%c\Microsoft\Internet Explorer\Quick Launch\User Pinned\TaskBar\Microsoft Edge.lnk" /q /f
		)
	)
)

for /f "usebackq tokens=2 delims=\" %%a in (`reg query "HKEY_USERS" ^| findstr /c:"S-"`) do (
	reg query "HKU\%%a" | findstr /c:"Volatile Environment" /c:"AME_UserHive_"
	if not !errorlevel! == 1 (
		CALL :USERREG "%%a"
	)
)

for /f "usebackq delims=" %%a in (`reg query "HKLM\SOFTWARE\WOW6432Node\Microsoft\Windows\CurrentVersion\Uninstall" ^| findstr /i /r /c:"Microsoft[ ]*Edge" /c:"msedge"`) do (
    reg delete "%%a" /f
)

for /f "usebackq delims=" %%a in (`dir /b /a:d "!SystemDrive!\Users" ^| findstr /v /i /x /c:"Public" /c:"Default User" /c:"All Users"`) do (
	del /q /f "!SystemDrive!\Users\%%a\Desktop\Microsoft Edge.lnk"
	del /q /f "!SystemDrive!\Users\%%a\AppData\Roaming\Microsoft\Internet Explorer\Quick Launch\User Pinned\TaskBar\Microsoft Edge.lnk"
	rmdir /q /s "!SystemDrive!\Users\%%a\AppData\Local\Microsoft\EdgeWebView"
	rmdir /q /s "!SystemDrive!\Users\%%a\AppData\Local\Microsoft\Edge"
	rmdir /q /s "!SystemDrive!\Users\%%a\AppData\Local\Microsoft\EdgeUpdate"
	rmdir /q /s "!SystemDrive!\Users\%%a\AppData\Local\Microsoft\EdgeCore"
)

for %%a in (
	"MicrosoftEdgeUpdateTaskMachineCore"
	"MicrosoftEdgeUpdateTaskMachineUA"
) do (
	schtasks /delete /tn "%%~a" /f
)

exit /b

:USERREG
for /f "usebackq tokens=1 delims= " %%a in (`reg query "HKU\%~1\SOFTWARE\Microsoft\Windows\CurrentVersion\Run" ^| findstr /i /c:"MicrosoftEdge" /c:"msedge"`) do (
	reg delete "HKU\%~1\SOFTWARE\Microsoft\Windows\CurrentVersion\Run" /v "%%a" /f
)
