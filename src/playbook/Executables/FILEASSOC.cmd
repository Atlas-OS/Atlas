@echo off

set baseAssociations=".bmp:PhotoViewer.FileAssoc.Tiff"^
 ".dib:PhotoViewer.FileAssoc.Tiff"^
 ".jfif:PhotoViewer.FileAssoc.Tiff"^
 ".jpe:PhotoViewer.FileAssoc.Tiff"^
 ".jpeg:PhotoViewer.FileAssoc.Tiff"^
 ".jpg:PhotoViewer.FileAssoc.Tiff"^
 ".jxr:PhotoViewer.FileAssoc.Tiff"^
 ".png:PhotoViewer.FileAssoc.Tiff"^
 ".tif:PhotoViewer.FileAssoc.Tiff"^
 ".tiff:PhotoViewer.FileAssoc.Tiff"^
 ".wdp:PhotoViewer.FileAssoc.Tiff"^
 ".url:IE.AssocFile.URL"

set braveAssociations="Proto:https:BraveHTML"^
 "Proto:http:BraveHTML"^
 ".htm:BraveHTML"^
 ".html:BraveHTML"^
 ".pdf:BraveFile"^
 ".shtml:BraveHTML"

set libreWolfAssociations="Proto:https:LibreWolfHTM"^
 "Proto:http:LibreWolfHTM"^
 ".htm:LibreWolfHTM"^
 ".html:LibreWolfHTM"^
 ".pdf:LibreWolfHTM"^
 ".shtml:LibreWolfHTM"

set chromeAssociations="Proto:https:ChromeHTML"^
 "Proto:http:ChromeHTML"^
 ".htm:ChromeHTML"^
 ".html:ChromeHTML"^
 ".pdf:ChromeHTML"^
 ".shtml:ChromeHTML"

if "%~1"=="" set associations=%baseAssociations%
if "%~1"=="Microsoft Edge" set associations=%baseAssociations%
if "%~1"=="Brave" set associations=%baseAssociations% %braveAssociations%
if "%~1"=="LibreWolf" set associations=%baseAssociations% %libreWolfAssociations%
if "%~1"=="Google Chrome" set associations=%baseAssociations% %chromeAssociations%

:: If the "Volatile Environment" key exists, that means it is a proper user. Built in accounts/SIDs don't have this key.
for /f "usebackq tokens=2 delims=\" %%a in (`reg query HKU ^| findstr /r /x /c:"HKEY_USERS\\S-.*" /c:"HKEY_USERS\\AME_UserHive_[^_]*"`) do (
    reg query "HKU\AME_UserHive_Default" | findstr /c:"Volatile Environment" /c:"AME_UserHive_" > nul && (
        echo Setting associations for "%%a"...
        powershell -NoP -EP Unrestricted -File assoc.ps1 "Placeholder" "%%a" %associations%
	)
)