@{
    Name        = 'Add Initialize-NewUser.ps1 script'
    Description = 'Adds the Initialize-NewUser.ps1 script to RunOnce, which applies any tweaks that are dynamically generated on new user creation'
    Registry    = @(
        # Default-user hive only: new accounts run Initialize-NewUser at first logon;
        # the installing account is configured during the install (custom.yml dispatches
        # Initialize-NewUser -FromInstall as the exact install-state-bound non-elevated user).
        # wscript.exe + Invoke-InitializeNewUserHidden.vbs launches with zero visible
        # window - powershell.exe's own -WindowStyle Hidden still flashes briefly because
        # its console exists before the process can hide itself. wscript.exe doesn't
        # evaluate PowerShell subexpressions (unlike powershell.exe, which used to expand
        # $(...) itself), so %windir% needs ExpandString/REG_EXPAND_SZ for Windows itself
        # to resolve it when it reads this RunOnce value.
        @{ Path = 'HKU\Atlas_DefaultUser\SOFTWARE\Microsoft\Windows\CurrentVersion\RunOnce'; Name = 'RunScript'; Type = 'ExpandString'; Data = '"%windir%\System32\wscript.exe" "%windir%\AtlasModules\Scripts\Invoke-InitializeNewUserHidden.vbs"' }
        @{ Path = 'HKU\Atlas_DefaultUser\SOFTWARE\Microsoft\Windows\CurrentVersion\Search'; Name = 'SearchboxTaskbarMode'; Type = 'DWord'; Data = 1 }
        @{ Path = 'HKU\Atlas_DefaultUser\SOFTWARE\Microsoft\Windows\CurrentVersion\Search'; Name = 'SearchboxTaskbarModeCache'; Type = 'DWord'; Data = 1 }
    )
    # Completion state lives only in each user's HKCU hive. The companion revokes the old
    # machine marker's explicit Users write grant without consuming any untrusted value,
    # then grants Users access to the shared logs needed by the first-logon phase.
    Script      = 'add-newUser-script.ps1'
}
