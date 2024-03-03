@echo off
setlocal EnableDelayedExpansion

:: This will only apply to logged in users
for /f "usebackq tokens=2 delims=\" %%a n (`reg query "HKEY_USERS" ^| findstr /r /x /c:"HKEY_USERS\\S-.*"`) do (
	REM If the "Volatile Environment" key exists, that means it is a proper user. Built in accounts/SIDs do not have this key.
	reg query "HKU\%%a" | findstr /c:"Volatile Environment" > nul 2>&1
	if not !errorlevel! == 1 (
		call :SETPFP "%%a"
	)
)

exit /b 0

:SETPFP
REM On recent Windows 10 versions, resolutions called for are:
REM 32x32, 40x40, 48x48, 64x64, 96x96, 192x192, 208x208, 240x240, 424x424,
REM 448x448, 1080x1080
set "usrPfpDir=!PUBLIC!\AccountPictures\%~1"

if exist "!usrPfpDir!" exit /b 0
mkdir "!usrPfpDir!" > nul 2>&1
PowerShell -NoP -C "Add-Type -AssemblyName System.Drawing; $img = [System.Drawing.Image]::FromFile((Get-Item '!ProgramData!\Microsoft\User Account Pictures\user.png')); $a = New-Object System.Drawing.Bitmap(32, 32); $graph = [System.Drawing.Graphics]::FromImage($a); $graph.DrawImage($img, 0, 0, 32, 32); $a.Save('!usrPfpDir!\32x32.png'); $b = New-Object System.Drawing.Bitmap(40, 40); $graph = [System.Drawing.Graphics]::FromImage($b); $graph.DrawImage($img, 0, 0, 40, 40); $b.Save('!usrPfpDir!\40x40.png'); $c = New-Object System.Drawing.Bitmap(48, 48); $graph = [System.Drawing.Graphics]::FromImage($c); $graph.DrawImage($img, 0, 0, 48, 48); $c.Save('!usrPfpDir!\48x48.png'); $d = New-Object System.Drawing.Bitmap(64, 64); $graph = [System.Drawing.Graphics]::FromImage($d); $graph.DrawImage($img, 0, 0, 64, 64); $d.Save('!usrPfpDir!\64x64.png'); $e = New-Object System.Drawing.Bitmap(96, 96); $graph = [System.Drawing.Graphics]::FromImage($e); $graph.DrawImage($img, 0, 0, 96, 96); $e.Save('!usrPfpDir!\96x96.png'); $f = New-Object System.Drawing.Bitmap(192, 192); $graph = [System.Drawing.Graphics]::FromImage($f); $graph.DrawImage($img, 0, 0, 192, 192); $f.Save('!usrPfpDir!\192x192.png'); $g = New-Object System.Drawing.Bitmap(208, 208); $graph = [System.Drawing.Graphics]::FromImage($g); $graph.DrawImage($img, 0, 0, 208, 208); $g.Save('!usrPfpDir!\208x208.png'); $h = New-Object System.Drawing.Bitmap(240, 240); $graph = [System.Drawing.Graphics]::FromImage($h); $graph.DrawImage($img, 0, 0, 240, 240); $h.Save('!usrPfpDir!\240x240.png'); $i = New-Object System.Drawing.Bitmap(424, 424); $graph = [System.Drawing.Graphics]::FromImage($i); $graph.DrawImage($img, 0, 0, 424, 424); $i.Save('!usrPfpDir!\424x424.png'); $j = New-Object System.Drawing.Bitmap(448, 448); $graph = [System.Drawing.Graphics]::FromImage($j); $graph.DrawImage($img, 0, 0, 448, 448); $j.Save('!usrPfpDir!\448x448.png'); $k = New-Object System.Drawing.Bitmap(1080, 1080); $graph = [System.Drawing.Graphics]::FromImage($k); $graph.DrawImage($img, 0, 0, 1080, 1080); $k.Save('!usrPfpDir!\1080x1080.png')"

set "usrPfpRegKey=HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows\CurrentVersion\AccountPicture\Users\%~1"

reg add "!usrPfpRegKey!" /f > nul
reg add "!usrPfpRegKey!" /v "Image32" /t REG_SZ /d "!usrPfpDir!\32x32.png" /f > nul
reg add "!usrPfpRegKey!" /v "Image40" /t REG_SZ /d "!usrPfpDir!\40x40.png" /f > nul
reg add "!usrPfpRegKey!" /v "Image48"/t REG_SZ /d "!usrPfpDir!\48x48.png" /f > nul
reg add "!usrPfpRegKey!" /v "Image64" /t REG_SZ /d "!usrPfpDir!\64x64.png" /f > nul
reg add "!usrPfpRegKey!" /v "Image96"/t REG_SZ /d "!usrPfpDir!\96x96.png" /f > nul
reg add "!usrPfpRegKey!" /v "Image192" /t REG_SZ /d "!usrPfpDir!\192x192.png" /f > nul
reg add "!usrPfpRegKey!" /v "Image208" /t REG_SZ /d "!usrPfpDir!\208x208.png" /f > nul
reg add "!usrPfpRegKey!" /v "Image240" /t REG_SZ /d "!usrPfpDir!\240x240.png" /f > nul
reg add "!usrPfpRegKey!" /v "Image424" /t REG_SZ /d "!usrPfpDir!\424x424.png" /f > nul
reg add "!usrPfpRegKey!" /v "Image448" /t REG_SZ /d "!usrPfpDir!\448x448.png" /f > nul
reg add "!usrPfpRegKey!" /v "Image1080" /t REG_SZ /d "!usrPfpDir!\1080x1080.png" /f > nul
