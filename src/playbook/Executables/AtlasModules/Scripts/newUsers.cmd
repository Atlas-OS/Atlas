@echo off

for /f "tokens=6 delims=[.] " %%a in ('ver') do (if %%a GEQ 22000 set win11=true)

set "title=Preparing Atlas user settings..."
title %title%

echo %title%
echo --------------------------------------------------------------------------------------
echo You'll be logged out, and once you login again, your new account will be ready for use.

(
    rem Kill Explorer
    taskkill /f /im explorer.exe

    rem Set visual effects
    call "%windir%\AtlasDesktop\3. Configuration\Visual Effects\Atlas Visual Effects (default).cmd" /silent

    rem Remove bitmap from 'New' context menu
    if defined win11 powershell -NoP -C "foreach ($key in $(Get-ChildItem -Path 'Registry::HKCR\Local Settings\MrtCache' -Recurse)) {gp ('Registry::' + $key) | % {foreach ($value in $($_.PSObject.Properties.Name | Where-Object {$_ -like '*ShellNewDisplayName_Bmp*'})) {sp -Path $key.PSPath -Name $value -Value ''}}}"

    rem Add 'Music' and 'Videos' to Quick Access (Home)
    powershell -NoP -C "$o = new-object -com shell.application; $o.Namespace($env:userprofile + '\Videos').Self.InvokeVerb('pintohome'); $o.Namespace($env:userprofile + '\Music').Self.InvokeVerb('pintohome')"

    rem Set taskbar search box to an icon
    reg add "HKCU\SOFTWARE\Microsoft\Windows\CurrentVersion\Search" /v "SearchboxTaskbarMode" /t REG_DWORD /d "1" /f

    rem Logout (not too fast so the user isn't confused)
    timeout /nobreak /t 10
    logoff
) > nul

exit