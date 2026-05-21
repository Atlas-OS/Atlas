taskkill /f /im OneDrive.exe > nul 2>&1
for %%a in (
	"%windir%\System32\OneDriveSetup.exe"
	"%windir%\SysWOW64\OneDriveSetup.exe"
) do (
	if exist "%%a" (
		"%%a" /uninstall > nul 2>&1
	)
)

:: trying winget as a fallback incase it cant find onedrive files
if not exist "%windir%\System32\OneDriveSetup.exe" if not exist "%windir%\SysWOW64\OneDriveSetup.exe" (
	winget uninstall --id "Microsoft.OneDrive" --silent --accept-source-agreements > nul 2>&1
	winget uninstall "Microsoft OneDrive" --silent --accept-source-agreements > nul 2>&1
)

:: If the "Volatile Environment" key exists, that means it is a proper user. Built in accounts/SIDs don't have this key.
for /f "usebackq tokens=2 delims=\" %%a in (`reg query HKU ^| findstr /r /x /c:"HKEY_USERS\\S-.*" /c:"HKEY_USERS\\AME_UserHive_[^_]*"`) do (
    reg query "HKU\%%a" | findstr /c:"Volatile Environment" /c:"AME_UserHive_" > nul && (
        echo Making changes for "%%a"...
        call :USERREG "%%a"
    )
)

rmdir /q /s "%ProgramData%\Microsoft OneDrive" > nul 2>&1
rmdir /q /s "%LOCALAPPDATA%\Microsoft\OneDrive" > nul 2>&1
rmdir /q /s "%SystemDrive%\OneDriveTemp" > nul 2>&1

for /f "usebackq delims=" %%a in (`dir /b /a:d "%SystemDrive%\Users"`) do (
	if exist "%SystemDrive%\Users\%%a\AppData\Local\Microsoft\OneDrive" rmdir /q /s "%SystemDrive%\Users\%%a\AppData\Local\Microsoft\OneDrive" > nul 2>&1
	if exist "%SystemDrive%\Users\%%a\OneDrive" rmdir /q /s "%SystemDrive%\Users\%%a\OneDrive" > nul 2>&1
	if exist "%SystemDrive%\Users\%%a\AppData\Roaming\Microsoft\Windows\Start Menu\Programs\OneDrive.lnk" del /q /f "%SystemDrive%\Users\%%a\AppData\Roaming\Microsoft\Windows\Start Menu\Programs\OneDrive.lnk" > nul 2>&1
)

for /f "usebackq delims=" %%a in (`reg query "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\SyncRootManager" 2^>nul ^| findstr /i /c:"OneDrive"`) do reg delete "%%a" /f > nul 2>&1

for /f "tokens=2 delims=\" %%a in ('schtasks /query /fo list /v 2^>nul ^| findstr /c:"\OneDrive Reporting Task" /c:"\OneDrive Standalone Update Task"') do (
	schtasks /delete /tn "%%a" /f > nul 2>&1
)

reg delete "HKLM\SOFTWARE\Classes\CLSID\{018D5C66-4533-4307-9B53-224DE2ED1FE6}" /f > nul 2>&1
reg delete "HKLM\SOFTWARE\Classes\WOW6432Node\CLSID\{018D5C66-4533-4307-9B53-224DE2ED1FE6}" /f > nul 2>&1
reg delete "HKLM\SOFTWARE\Classes\CLSID\{A0A7DEC5-B1A7-4A47-847D-1D005787621E}" /f > nul 2>&1
reg delete "HKLM\SOFTWARE\Classes\WOW6432Node\CLSID\{A0A7DEC5-B1A7-4A47-847D-1D005787621E}" /f > nul 2>&1

exit /b

:USERREG
for /f "usebackq delims=" %%a in (`reg query "HKU\%~1\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\BannerStore" 2^>nul ^| findstr /i /c:"OneDrive" 2^>nul`) do (
	reg delete "%%a" /f > nul 2>&1
)
for /f "usebackq delims=" %%a in (`reg query "HKU\%~1\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\AutoplayHandlers\Handlers" 2^>nul ^| findstr /i /c:"OneDrive" 2^>nul`) do (
	reg delete "%%a" /f > nul 2>&1
)
for /f "usebackq delims=" %%a in (`reg query "HKU\%~1\SOFTWARE\Microsoft\Windows\CurrentVersion\App Paths" 2^>nul ^| findstr /i /c:"OneDrive" 2^>nul`) do (
	reg delete "%%a" /f > nul 2>&1
)
for /f "usebackq delims=" %%a in (`reg query "HKU\%~1\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall" 2^>nul ^| findstr /i /c:"OneDrive" 2^>nul`) do (
	reg delete "%%a" /f > nul 2>&1
)

reg delete "HKU\%~1\SOFTWARE\Classes\CLSID\{018D5C66-4533-4307-9B53-224DE2ED1FE6}" /f > nul 2>&1
reg delete "HKU\%~1\SOFTWARE\Classes\WOW6432Node\CLSID\{018D5C66-4533-4307-9B53-224DE2ED1FE6}" /f > nul 2>&1
reg delete "HKU\%~1\SOFTWARE\Classes\CLSID\{A0A7DEC5-B1A7-4A47-847D-1D005787621E}" /f > nul 2>&1
reg delete "HKU\%~1\SOFTWARE\Classes\WOW6432Node\CLSID\{A0A7DEC5-B1A7-4A47-847D-1D005787621E}" /f > nul 2>&1
reg delete "HKU\%~1\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\Desktop\NameSpace\{018D5C66-4533-4307-9B53-224DE2ED1FE6}" /f > nul 2>&1
reg delete "HKU\%~1\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\Desktop\NameSpace\{A0A7DEC5-B1A7-4A47-847D-1D005787621E}" /f > nul 2>&1

reg delete "HKU\%~1\Environment" /v "OneDrive" /f > nul 2>&1
reg delete "HKU\%~1\SOFTWARE\Microsoft\Windows\CurrentVersion\Run" /v "OneDriveSetup" /f > nul 2>&1

:: Fix folder redirection - this sometimes persists after uninstallation for whatever reason
set "___sf=HKU\%~1\Software\Microsoft\Windows\CurrentVersion\Explorer\User Shell Folders"
reg add "%___sf%" /v "{F42EE2D3-909F-4907-8871-4C22FC0BF756}" /t REG_EXPAND_SZ /d "%%USERPROFILE%%\Documents" /f > nul 2>&1
reg add "%___sf%" /v "Personal" /t REG_EXPAND_SZ /d "%%USERPROFILE%%\Documents" /f > nul 2>&1
reg add "%___sf%" /v "Desktop" /t REG_EXPAND_SZ /d "%%USERPROFILE%%\Desktop" /f > nul 2>&1
reg add "%___sf%" /v "My Pictures" /t REG_EXPAND_SZ /d "%%USERPROFILE%%\Pictures" /f > nul 2>&1
reg add "%___sf%" /v "{0DDD015D-B06C-45D5-8C4C-F59713854639}" /t REG_EXPAND_SZ /d "%%USERPROFILE%%\Pictures" /f > nul 2>&1
