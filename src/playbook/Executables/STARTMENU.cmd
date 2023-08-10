@echo off

copy /y "Layout.xml" "%SystemDrive%\Users\Default\AppData\Local\Microsoft\Windows\Shell\StartMenuLayout.xml"
copy /y "Layout.json" "%SystemDrive%\Users\Default\AppData\Local\Microsoft\Windows\Shell\StartMenuLayout.json"

for /f "usebackq tokens=2 delims=\" %%a in (`reg query "HKEY_USERS" ^| findstr /r /x /c:"HKEY_USERS\\S-.*" /c:"HKEY_USERS\\AME_UserHive_[^_]*"`) do (
	REM If the "Volatile Environment" key exists, that means it is a proper user. Built in accounts/SIDs don't have this key.
	reg query "HKEY_USERS\%%a" | findstr /c:"Volatile Environment" /c:"AME_UserHive_" > NUL 2>&1
	if not errorlevel 1 (
		for /f "usebackq tokens=4* delims= " %%c in (`reg query "HKU\%%a\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\Shell Folders" /v "Local AppData" ^| findstr /r /x /c:".*Local AppData[ ]*REG_SZ[ ].*"`) do (
			copy /y "Layout.xml" "%%c\Microsoft\Windows\Shell\StartMenuLayout.xml"
			copy /y "Layout.json" "%%c\Microsoft\Windows\Shell\StartMenuLayout.json"

			rem Clear Start Menu pinned items
			for /f "usebackq delims=" %%d in (`dir /b "%%c\Packages" /a:d ^| findstr /c:"Microsoft.Windows.StartMenuExperienceHost"`) do (
				for /f "usebackq delims=" %%e in (`dir /b "%%c\Packages\%%d\LocalState" /a:-d ^| findstr /R /c:"start.\.bin" /c:"start\.bin"`) do del /q /f "%%c\Packages\%%d\LocalState\%%e"
			)
		)
		reg add "HKU\%%a\SOFTWARE\Policies\Microsoft\Windows\Explorer" /v "StartLayoutFile" /t REG_SZ /d "C:\Windows\StartMenuLayout.xml" /f
		for /f "usebackq delims=" %%c in (`reg query "HKU\%%a\SOFTWARE\Microsoft\Windows\CurrentVersion\CloudStore\Store\Cache\DefaultAccount" ^| findstr /c:"start.tilegrid"`) do (
			reg delete "%%c" /f
		)
	)
)