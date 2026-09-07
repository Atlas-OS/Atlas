@{
    Name = 'Register user upgrade migration'
    Description = 'Applies the installed version to existing profiles at their next sign-in, preserving desktop layout.'
    OnUpgrade = 'Only'
    Registry = @(
        @{ Path = 'HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Run'; Name = 'AtlasUserUpgrade'; Type = 'ExpandString'; Data = '"%windir%\System32\wscript.exe" "%windir%\AtlasModules\Scripts\Entry\Invoke-AtlasUserUpgradeHidden.vbs"' }
    )
}
