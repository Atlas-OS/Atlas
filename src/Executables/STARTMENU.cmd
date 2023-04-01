@echo off
setlocal EnableDelayedExpansion

if exist "!SystemDrive!\Windows\StartMenuLayout.xml" echo del /q /f "!SystemDrive!\Windows\StartMenuLayout.xml" & del /q /f "!SystemDrive!\Windows\StartMenuLayout.xml"
copy /y "Layout.xml" "!SystemDrive!\Windows\StartMenuLayout.xml"
taskkill /f /im "SearchApp.exe"

for /f "usebackq tokens=2 delims=\" %%a in (`reg query "HKEY_USERS" ^| findstr /r /x /c:"HKEY_USERS\\S-.*" /c:"HKEY_USERS\\AME_UserHive_[^_]*"`) do (
	REM If the "Volatile Environment" key exists, that means it is a proper user. Built in accounts/SIDs do not have this key.
	reg query "HKEY_USERS\%%a" | findstr /c:"Volatile Environment" /c:"AME_UserHive_" > nul 2>&1
	if not !errorlevel! == 1 (
		for /f "usebackq tokens=3* delims= " %%c in (`reg query "HKU\%%a\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\Shell Folders" /v "Local AppData" ^| findstr /r /x /c:".*Local AppData[ ]*REG_SZ[ ].*"`) do (
			echo copy /y "Layout.xml" "%%c\Microsoft\Windows\Shell\LayoutModification.xml"
			copy /y "Layout.xml" "%%c\Microsoft\Windows\Shell\LayoutModification.xml"
			echo del /q /f "%%c\Packages\Microsoft.Windows.Search_cw5n1h2txyewy\LocalState\DeviceSearchCache\SettingsCache.txt"
			del /q /f "%%c\Packages\Microsoft.Windows.Search_cw5n1h2txyewy\LocalState\DeviceSearchCache\SettingsCache.txt"
			echo copy /y "SettingsCache.txt" "%%c\Packages\Microsoft.Windows.Search_cw5n1h2txyewy\LocalState\DeviceSearchCache\SettingsCache.txt"
			copy /y "SettingsCache.txt" "%%c\Packages\Microsoft.Windows.Search_cw5n1h2txyewy\LocalState\DeviceSearchCache\SettingsCache.txt"
		)
		echo reg add "HKU\%%a\SOFTWARE\Policies\Microsoft\Windows\Explorer" /f
		reg add "HKU\%%a\SOFTWARE\Policies\Microsoft\Windows\Explorer" /f
		echo reg add "HKU\%%a\SOFTWARE\Policies\Microsoft\Windows\Explorer" /v "LockedStartLayout" /t REG_DWORD /d "0" /f
		reg add "HKU\%%a\SOFTWARE\Policies\Microsoft\Windows\Explorer" /v "LockedStartLayout" /t REG_DWORD /d "0" /f
		echo reg add "HKU\%%a\SOFTWARE\Policies\Microsoft\Windows\Explorer" /v "StartLayoutFile" /t REG_SZ /d "C:\Windows\StartMenuLayout.xml" /f
		reg add "HKU\%%a\SOFTWARE\Policies\Microsoft\Windows\Explorer" /v "StartLayoutFile" /t REG_SZ /d "C:\Windows\StartMenuLayout.xml" /f
		for /f "usebackq delims=" %%c in (`reg query "HKU\%%a\SOFTWARE\Microsoft\Windows\CurrentVersion\CloudStore\Store\Cache\DefaultAccount" ^| findstr /c:"start.tilegrid"`) do (
			echo reg delete "%%c" /f
			reg delete "%%c" /f
		)
	)
)

PowerShell -NoP -C "Import-StartLayout -LayoutPath '!SystemDrive!\Windows\StartMenuLayout.xml' -MountPath $env:SystemDrive\\"
reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows\Explorer" /f
reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows\Explorer" /v "StartLayoutFile" /t REG_SZ /d "!SystemDrive!\Windows\StartMenuLayout.xml" /f
