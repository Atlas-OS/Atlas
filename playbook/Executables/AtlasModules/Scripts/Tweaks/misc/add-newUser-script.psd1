@{
    Name        = 'Add Initialize-NewUser.ps1 script'
    Description = 'Adds the Initialize-NewUser.ps1 script to RunOnce, which applies any tweaks that are dynamically generated on new user creation'
    Registry    = @(
        # The $(...) subexpression is expanded by PowerShell when RunOnce executes the
        # command on first logon, not at install time - keep it literal.
        @{ Path = 'HKU\AME_UserHive_Default\SOFTWARE\Microsoft\Windows\CurrentVersion\RunOnce'; Name = 'RunScript'; Type = 'String'; Data = 'powershell -EP RemoteSigned -NoP & """$([Environment]::GetFolderPath(''Windows''))\AtlasModules\Scripts\Initialize-NewUser.ps1"""' }
        @{ Path = 'HKU\AME_UserHive_Default\SOFTWARE\Microsoft\Windows\CurrentVersion\Search'; Name = 'SearchboxTaskbarMode'; Type = 'DWord'; Data = 1 }
        @{ Path = 'HKU\AME_UserHive_Default\SOFTWARE\Microsoft\Windows\CurrentVersion\Search'; Name = 'SearchboxTaskbarModeCache'; Type = 'DWord'; Data = 1 }
    )
    # Creates the HKLM marker key the script needs, with an ACL letting Users write to it.
    Script      = 'add-newUser-script.ps1'
}
