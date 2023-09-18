@echo off
setlocal EnableDelayedExpansion

whoami /user | find /i "S-1-5-18" > nul 2>&1 || (
	call RunAsTI.cmd "%~f0" %*
	exit /b
)

for %%a in (
	"bluetooth"
	"zipfolder"
	"mail"
	"documents"
	"removableDrives"
) do (
	set "%%~a=false"
)

for /f "usebackq tokens=*" %%a in (
	`multichoice.exe "Send To Debloat" "Tick the default 'Send To' context menu items that you want to disable here (un-checked items are enabled)" "Bluetooth device;Compressed (zipped) folder;Desktop (create shortcut);Mail recipient;Documents;Removable Drives"`
) do (set items=%%a)
for %%a in ("%items:;=" "%") do (
	if "%%~a" == "Bluetooth device" (set bluetooth=true)
	if "%%~a" == "Compressed (zipped) folder" (set zipfolder=true)
	if "%%~a" == "Desktop (create shortcut)" (set desktop=true)
	if "%%~a" == "Mail recipient" (set mail=true)
	if "%%~a" == "Documents" (set documents=true)
	if "%%~a" == "Removable Drives" (set removableDrives=true)
)
if "!bluetooth!" == "true" (attrib +h "!APPDATA!\Microsoft\Windows\SendTo\Bluetooth File Transfer.LNK") else (attrib -h "!APPDATA!\Microsoft\Windows\SendTo\Bluetooth File Transfer.LNK")
if "!zipfolder!" == "true" (attrib +h "!APPDATA!\Microsoft\Windows\SendTo\Compressed (zipped) Folder.ZFSendToTarget") else (attrib -h "!APPDATA!\Microsoft\Windows\SendTo\Compressed (zipped) Folder.ZFSendToTarget")
if "!desktop!" == "true" (attrib +h "!APPDATA!\Microsoft\Windows\SendTo\Desktop (create shortcut).DeskLink") else (attrib -h "!APPDATA!\Microsoft\Windows\SendTo\Desktop (create shortcut).DeskLink")
if "!mail!" == "true" (attrib +h "!APPDATA!\Microsoft\Windows\SendTo\Mail Recipient.MAPIMail") else (attrib -h "!APPDATA!\Microsoft\Windows\SendTo\Mail Recipient.MAPIMail")
if "!documents!" == "true" (attrib +h "!APPDATA!\Microsoft\Windows\SendTo\Documents.mydocs") else (attrib -h "!APPDATA!\Microsoft\Windows\SendTo\Documents.mydocs")
if "!removableDrive!" == "true" (
	reg add "HKCU\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\Explorer" /v "NoDrivesInSendToMenu" /t REG_DWORD /d "1" /f > nul 2>&1
) else (
	reg delete "HKCU\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\Explorer" /v "NoDrivesInSendToMenu" /f > nul 2>&1
)
for /f "usebackq tokens=*" %%a in (`multichoice "Explorer Restart" "You need to restart File Explorer to fully apply the changes." "Restart now"`) do (
	if "%%a" == "Restart now" (
		taskkill /f /im explorer.exe > nul 2>&1
		start explorer.exe
	)
)

echo Finished, changes have been applied.
pause
exit /b