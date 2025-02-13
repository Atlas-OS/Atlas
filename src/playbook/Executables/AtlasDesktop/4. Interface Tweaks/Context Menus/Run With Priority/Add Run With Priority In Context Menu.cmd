@echo off
:: Change to match the setting name (e.g., Sleep, Indexing, etc.)
set "settingName=RunWithPriority"
:: Change to 0 (Disabled) or 1 (Enabled) etc
set "stateValue=1"
set "scriptPath=%~f0"

set "___args="%~f0" %*"
fltmc > nul 2>&1 || (
    echo Administrator privileges are required.
    powershell -c "Start-Process -Verb RunAs -FilePath 'cmd' -ArgumentList """/c $env:___args"""" 2> nul || (
        echo You must run this script as admin.
        if "%*"=="" pause
        exit /b 1
    )
    exit /b
)

:: Update Registry (State and Path)
reg add "HKLM\SOFTWARE\AtlasOS\%settingName%" /v state /t REG_DWORD /d %stateValue% /f > nul
reg add "HKLM\SOFTWARE\AtlasOS\%settingName%" /v path /t REG_SZ /d "%scriptPath%" /f > nul

:: End of state and path update

reg add "HKCR\exefile\Shell\Priority\shell\001flyout" /d "Realtime" /f > nul
reg add "HKCR\exefile\Shell\Priority\shell\001flyout\command" /d "powershell start -file 'cmd' -args '/c start \"\"\"Realtime App\"\"\" /Realtime \"\"\"%1\"\"\"' -verb runas" /f > nul
reg add "HKCR\exefile\Shell\Priority\shell\002flyout" /d "High" /f > nul
reg add "HKCR\exefile\Shell\Priority\shell\002flyout\command" /d "cmd /c start \"\" /High \"%1\"" /f > nul
reg add "HKCR\exefile\Shell\Priority\shell\003flyout" /d "Above normal" /f > nul
reg add "HKCR\exefile\Shell\Priority\shell\003flyout\command" /d "cmd /c start \"\" /AboveNormal \"%1\"" /f > nul
reg add "HKCR\exefile\Shell\Priority\shell\004flyout" /d "Normal" /f > nul
reg add "HKCR\exefile\Shell\Priority\shell\004flyout\command" /d "cmd /c start \"\" /Normal \"%1\"" /f > nul
reg add "HKCR\exefile\Shell\Priority\shell\005flyout" /d "Below normal" /f > nul
reg add "HKCR\exefile\Shell\Priority\shell\005flyout\command" /d "cmd /c start \"\" /BelowNormal \"%1\"" /f > nul
reg add "HKCR\exefile\Shell\Priority\shell\006flyout" /d "Low" /f > nul
reg add "HKCR\exefile\Shell\Priority\shell\006flyout\command" /d "cmd /c start \"\" /Low \"%1\"" /f > nul


echo Changes applied successfully.
echo Press any key to exit...
pause > nul
exit /b