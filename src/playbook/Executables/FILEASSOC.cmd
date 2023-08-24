@echo off

for /f "usebackq tokens=2 delims=\" %%A in (`reg query "HKEY_USERS" ^| findstr /r /x /c:"HKEY_USERS\\S-.*" /c:"HKEY_USERS\\AME_UserHive_[^_]*"`) do (
	REM If the "Volatile Environment" key exists, that means it is a proper user. Built in accounts/SIDs don't have this key.
	reg query "HKU\%%A" | findstr /c:"Volatile Environment" /c:"AME_UserHive_" > NUL 2>&1
		if not errorlevel 1 (
			PowerShell -NoP -ExecutionPolicy Bypass -File assoc.ps1 "Placeholder" "%%A" ".bmp:PhotoViewer.FileAssoc.Tiff" ".dib:PhotoViewer.FileAssoc.Tiff" ".jfif:PhotoViewer.FileAssoc.Tiff" ".jpe:PhotoViewer.FileAssoc.Tiff" ".jpeg:PhotoViewer.FileAssoc.Tiff" ".jpg:PhotoViewer.FileAssoc.Tiff" ".jxr:PhotoViewer.FileAssoc.Tiff" ".png:PhotoViewer.FileAssoc.Tiff" ".tif:PhotoViewer.FileAssoc.Tiff" ".tiff:PhotoViewer.FileAssoc.Tiff" ".wdp:PhotoViewer.FileAssoc.Tiff"
	)
)
