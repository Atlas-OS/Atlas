@echo off

:: Check if user is on Windows 11
for /f "tokens=6 delims=[.] " %%a in ('ver') do (if %%a LSS 22000 set win10=true)

:: Set hidden Windows Settings pages
:: There's some specific Windows 11/10 additions or removals
:: https://learn.microsoft.com/en-us/windows/uwp/launch-resume/launch-settings-app#ms-settings-uri-scheme-reference

set hiddenPages=hide:^
crossdevice;^
recovery;^
autoplay;^
usb;^
maps;^
maps-downloadmaps;^
findmydevice;^
privacy;^
privacy-speech;^
privacy-feedback;^
privacy-activityhistory;^
search-permissions;^
privacy-location;^
privacy-general;^
sync;^
printers;^
cortana-windowssearch

:: Set 10-only changes
if defined win10 (
    set regVariable=USERREG10

    rem Set dual boot menu description to AtlasOS 10
    bcdedit /set description "AtlasOS 10" > nul

    rem Delete 11-only tweaks
    rd /s /q "%windir%\AtlasDesktop\3. Configuration\Background Apps" > nul
    rd /s /q "%windir%\AtlasDesktop\3. Configuration\Power\Timer Resolution" > nul
    rd /s /q "%windir%\AtlasDesktop\4. Optional Tweaks\File Explorer Customization\Compact View" > nul
    rd /s /q "%windir%\AtlasDesktop\4. Optional Tweaks\Windows 11 Context Menu" > nul
    del /f /q "%windir%\AtlasModules\Tools\TimerResolution.exe" > nul

    rem Set hidden Settings pages
    reg add "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\Explorer" /v "SettingsPageVisibility" /t REG_SZ /d "%hiddenPages%;backup;" /f > nul
) else (
    set regVariable=USERREG
)

:: If the "Volatile Environment" key exists, that means it is a proper user. Built in accounts/SIDs do not have this key.
for /f "usebackq tokens=2 delims=\" %%a in (`reg query HKU ^| findstr /r /x /c:"HKEY_USERS\\S-.*" /c:"HKEY_USERS\\AME_UserHive_[^_]*"`) do (
    reg query "HKU\%%a" | findstr /c:"Volatile Environment" /c:"AME_UserHive_" > nul && (
        echo Applying %regVariable% changes to "%%a"...
        call :%regVariable% "%%a"
    )
)
if defined win10 exit /b

:::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
:: WINDOWS 11-ONLY CHANGES                                     ::
:::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::

:: Remove volume flyout
rd /s /q "%windir%\AtlasDesktop\3. Configuration\4. Optional Tweaks\Volume Flyout" > nul

:: Set hidden Settings pages
reg add "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\Explorer" /v "SettingsPageVisibility" /t REG_SZ /d "%hiddenPages%;family-group;deviceusage;home;" /f > nul

:: Disable Windows Chat in the taskbar
reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows\Windows Chat" /v "ChatIcon" /t REG_DWORD /d "3" /f > nul

:: Disable Copilot
reg add "HKLM\Software\Policies\Microsoft\Windows\WindowsCopilot" /v "TurnOffWindowsCopilot" /t REG_DWORD /d "1" /f > nul

:: Set dual boot menu description to AtlasOS 11
bcdedit /set description "AtlasOS 11" > nul

:: Re-enable Action Center on Win11, as it breaks calendar
reg delete "HKLM\SOFTWARE\Policies\Microsoft\Windows\Explorer" /v "DisableNotificationCenter" /f > nul 2>&1

:: Restore Music and Videos folders by clearing up Quick Access' cache
del /f /q "%APPDATA%\Microsoft\Windows\Recent\AutomaticDestinations\f01b4d95cf55d32a.automaticDestinations-ms" > nul 2>&1

exit /b

:::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
:: WINDOWS 10-ONLY USER REGISTRY CHANGES                       ::
:::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::

:USERREG10
:: Set unpinned Notification Center items
reg add "HKU\%~1\Control Panel\Quick Actions\Control Center\Unpinned" /v "Microsoft.QuickAction.Connect" /t REG_NONE /d "" /f > nul
reg add "HKU\%~1\Control Panel\Quick Actions\Control Center\Unpinned" /v "Microsoft.QuickAction.Location" /t REG_NONE /d "" /f > nul
reg add "HKU\%~1\Control Panel\Quick Actions\Control Center\Unpinned" /v "Microsoft.QuickAction.ScreenClipping" /t REG_NONE /d "" /f > nul
reg add "HKU\%~1\Control Panel\Quick Actions\Control Center\QuickActionsStateCapture" /v "Toggles" /t REG_SZ /d "Toggles,Microsoft.QuickAction.BlueLightReduction:false,Microsoft.QuickAction.AllSettings:false,Microsoft.QuickAction.Project:false" /f > nul

exit /b

:::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
:: WINDOWS 11-ONLY USER REGISTRY CHANGES                       ::
:::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::

:USERREG
:: Do not show recommendations for tips, shortcuts, new apps, and more in start menu
reg add "HKU\%~1\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" /v "Start_IrisRecommendations" /t REG_DWORD /d "0" /f > nul

:: Show more pins in Start menu
reg add "HKU\%~1\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" /v "Start_Layout" /t REG_DWORD /d "1" /f > nul

:: Compact mode in Explorer
reg add "HKU\%~1\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" /v "UseCompactMode" /t REG_DWORD /d "1" /f > nul

:: Put taskbar to the left
reg add "HKU\%~1\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" /v "TaskbarAl" /t REG_DWORD /d "0" /f > nul

:: Do not show account related notifications occasionally in start menu
reg add "HKU\%~1\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" /v "Start_AccountNotifications" /t REG_DWORD /d "0" /f > nul

:: Remove Widgets button from taskbar
reg add "HKU\%~1\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" /v "TaskbarDa" /t REG_DWORD /d "0" /f > nul

:: Remove Chat button from taskbar
reg add "HKU\%~1\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" /v "TaskbarMn" /t REG_DWORD /d "0" /f > nul

:: Do not show the voice typing microphone button
reg add "HKU\%~1\Software\Microsoft\input\Settings" /v "IsVoiceTypingKeyEnabled" /t REG_DWORD /d "0" /f > nul

:: Do not show files from Office.com
reg add "HKU\%~1\Software\Microsoft\Windows\CurrentVersion\Explorer" /v "ShowCloudFilesInQuickAccess" /t REG_DWORD /d "0" /f > nul

:: Restore old Windows 10 context menu
reg add "HKU\%~1\Software\Classes\CLSID\{86ca1aa0-34aa-4e8b-a509-50c905bae2a2}\InprocServer32" /f /ve > nul

:: Set unpinned Notification Center items
reg add "HKU\%~1\Control Panel\Quick Actions\Control Center\Unpinned" /v "Microsoft.QuickAction.Cast" /t REG_NONE /d "" /f > nul
reg add "HKU\%~1\Control Panel\Quick Actions\Control Center\Unpinned" /v "Microsoft.QuickAction.NearShare" /t REG_NONE /d "" /f > nul
reg add "HKU\%~1\Control Panel\Quick Actions\Control Center\QuickActionsStateCapture" /v "Toggles" /t REG_SZ /d "Toggles,Microsoft.QuickAction.BlueLightReduction:false,Microsoft.QuickAction.Accessibility:false,Microsoft.QuickAction.ProjectL2:false" /f > nul

:: Remove 'Bitmap File' from 'New' context menu
set "mrtCache=HKEY_USERS\%~1\Software\Classes\Local Settings\MrtCache"
echo %~1 | find "_Classes" > nul
if errorlevel 1 (
    for /f "tokens=*" %%a in ('reg query "%mrtCache%" /s ^| find /i "%mrtCache%"') do (
        for /f "tokens=1-2" %%b in ('reg query "%%a" /v * ^| find /i "ShellNewDisplayName_Bmp"') do (
            reg add "%%a" /v "%%b %%c" /t REG_SZ /d "" /f
        )
    )
)

exit /b