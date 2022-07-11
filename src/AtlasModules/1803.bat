@echo off
:: Remove irrelevant directories
set SetupDir=C:%homepath%\Desktop\Atlas
rmdir /s /q "%SetupDir%\3. Configuration\Printing" >nul 2>nul
rmdir /s /q "C:\Users\Default\Desktop\Atlas\3. Configuration\Printing" >nul 2>nul
goto :EOF
