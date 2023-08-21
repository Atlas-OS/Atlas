@echo off
setlocal EnableDelayedExpansion

:: make it so the user isn't locked out
net accounts /lockoutthreshold:0

:: make passwords never expire
net accounts /maxpwage:unlimited

for /f "usebackq delims=" %%a in (`PowerShell -NoP -C "(Get-LocalUser | Where {$_.PrincipalSource -eq 'MicrosoftAccount'}).Name"`) do call :CONVERTUSER "%%a"
for /f "usebackq delims=" %%a in (`reg query "HKLM\SOFTWARE\Microsoft\IdentityStore\LogonCache\Name2Sid" ^| findstr /i /c:"Name2Sid"`) do reg delete "%%a" /f > nul
for /f "usebackq delims=" %%a in (`reg query "HKLM\SOFTWARE\Microsoft\IdentityStore\LogonCache\Sid2Name" ^| findstr /i /c:"Sid2Name"`) do reg delete "%%a" /f > nul

rmdir /q /s "!windir!\System32\config\systemprofile\AppData\Local\Microsoft\Windows\CloudAPCache" > nul

exit /b

:CONVERTUSER
for /f "usebackq delims=" %%a in (`reg query "HKLM\SAM\SAM\Domains\Account\Users" ^| findstr /i /c:"Account\Users"`) do (
	for /f "usebackq tokens=1 delims= " %%c in (`reg query "%%a" ^| findstr /r /c:"[]*Internet" /c:"GivenName" /c:"Surname"`) do reg delete "%%a" /v "%%c" /f > nul
)

for /f "usebackq delims=" %%a in (`PowerShell -NoP -C "(New-Object -ComObject Microsoft.DiskQuota).TranslateLogonNameToSID('%~1')"`) do set "userSID=%%a"
reg add "HKU\!userSID!\SOFTWARE\Microsoft\Windows\CurrentVersion\AccountState" /v "ExplicitLocal" /t REG_DWORD /d "1" /f > nul
reg delete "HKU\!userSID!\SOFTWARE\Microsoft\IdentityCRL" /f > nul
for /f "usebackq delims=" %%a in (`reg query "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Authentication\Credential Providers" /s /f "!userSID!" ^| findstr /c:"!userSID!"`) do reg delete "%%a" /f > nul

net user "%~1" /fullname:"" > nul
net user "%~1" "" > nul
wmic UserAccount where name='%~1' set Passwordexpires=true > nul
net user "%~1" /logonpasswordchg:yes > nul