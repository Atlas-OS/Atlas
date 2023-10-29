@echo off

copy /y "Layout.xml" "%SystemDrive%\Users\Default\AppData\Local\Microsoft\Windows\Shell\LayoutModification.xml" > nul

:: If the "Volatile Environment" key exists, that means it is a proper user. Built in accounts/SIDs don't have this key.
for /f "usebackq tokens=2 delims=\" %%a in (`reg query "HKEY_USERS" ^| findstr /r /x /c:"HKEY_USERS\\S-.*" /c:"HKEY_USERS\\AME_UserHive_[^_]*"`) do (
	reg query "HKEY_USERS\%%a" | findstr /c:"Volatile Environment" /c:"AME_UserHive_" > nul && (
		for /f "usebackq tokens=4* delims= " %%c in (`reg query "HKU\%%a\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\Shell Folders" /v "Local AppData" 2^>nul ^| findstr /r /x /c:".*Local AppData[ ]*REG_SZ[ ].*" 2^>nul`) do (
			copy /y "Layout.xml" "%%c\Microsoft\Windows\Shell\LayoutModification.xml" > nul

			rem Clear Start Menu pinned items
			for /f "usebackq delims=" %%d in (`dir /b "%%c\Packages" /a:d ^| findstr /c:"Microsoft.Windows.StartMenuExperienceHost"`) do (
				for /f "usebackq delims=" %%e in (`dir /b "%%c\Packages\%%d\LocalState" /a:-d ^| findstr /R /c:"start.\.bin" /c:"start\.bin"`) do (
					del /q /f "%%c\Packages\%%d\LocalState\%%e" > nul 2>&1
				)
			)
		)
		for /f "usebackq delims=" %%c in (`reg query "HKU\%%a\SOFTWARE\Microsoft\Windows\CurrentVersion\CloudStore\Store\Cache\DefaultAccount" 2^>nul ^| findstr /c:"start.tilegrid" 2^>nul`) do (
			reg delete "%%c" /f > nul 2>&1
		)
		
		rem Remove advertisements from Start Menu (23H2+)
		reg delete "HKU\%%a\SOFTWARE\Microsoft\Windows\CurrentVersion\Start" /v "Config" /f > nul 2>&1
	)
)
