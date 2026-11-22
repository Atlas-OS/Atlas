@{
    Name = 'Register user upgrade migration'
    Description = 'Updates existing accounts to the installed version at their next sign-in, keeping their desktop layout.'
    OnUpgrade = 'Only'
    Registry = @(
        @{ Path = 'HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Run'; Name = 'AtlasUserUpgrade'; Type = 'ExpandString'; Data = '"%windir%\System32\wscript.exe" "%windir%\AtlasModules\Scripts\Entry\Invoke-AtlasUserUpgradeHidden.vbs"' }
    )
}
