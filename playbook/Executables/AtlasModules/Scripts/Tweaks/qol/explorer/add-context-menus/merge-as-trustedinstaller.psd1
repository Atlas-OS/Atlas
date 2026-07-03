@{
    Name        = 'Add ''Merge as TrustedInstaller'' to Context Menu'
    Description = 'Adds ''Merge as TrustedInstaller'' to context menu for registry files'
    Registry    = @(
        @{ Path = 'HKLM:\Software\Classes\regfile\Shell\RunAs'; Name = 'HasLUAShield'; Type = 'String'; Data = '1' }
    )
    # The default ('') values cannot be expressed in the Registry schema (a value name
    # is required), so they are written by the companion script.
    Script      = 'merge-as-trustedinstaller.ps1'
}
