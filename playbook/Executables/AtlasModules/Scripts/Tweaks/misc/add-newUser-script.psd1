@{
    Name        = 'Add Initialize-NewUser.ps1 script'
    Description = 'Adds the Initialize-NewUser.ps1 script to RunOnce, which applies any tweaks that are dynamically generated on new user creation'
    Registry    = @(
        # Default-user hive only: new accounts run Initialize-NewUser at first logon, and
        # the installing account runs Initialize-NewUser -FromInstall during the install as
        # itself, without elevation. wscript.exe and Invoke-InitializeNewUserHidden.vbs
        # show no window, where powershell.exe -WindowStyle Hidden still flashes its
        # console. %windir% needs ExpandString (REG_EXPAND_SZ) so Windows expands it
        # when it reads this RunOnce value.
        @{ Path = 'HKU\Atlas_DefaultUser\SOFTWARE\Microsoft\Windows\CurrentVersion\RunOnce'; Name = 'RunScript'; Type = 'ExpandString'; Data = '"%windir%\System32\wscript.exe" "%windir%\AtlasModules\Scripts\Entry\Invoke-InitializeNewUserHidden.vbs"' }
        @{ Path = 'HKU\Atlas_DefaultUser\SOFTWARE\Microsoft\Windows\CurrentVersion\Search'; Name = 'SearchboxTaskbarMode'; Type = 'DWord'; Data = 1 }
        @{ Path = 'HKU\Atlas_DefaultUser\SOFTWARE\Microsoft\Windows\CurrentVersion\Search'; Name = 'SearchboxTaskbarModeCache'; Type = 'DWord'; Data = 1 }
    )
    # Completion state lives only in each user's HKCU hive. The companion revokes Users
    # write access on the old machine marker, without reading it, and on the install logs.
    Script      = 'add-newUser-script.ps1'
}
