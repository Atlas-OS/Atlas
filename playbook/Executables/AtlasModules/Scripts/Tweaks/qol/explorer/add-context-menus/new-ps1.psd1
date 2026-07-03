@{
    Name        = 'Add PowerShell Script to ''New'' Context Menu'
    Description = 'Adds PowerShell script (.ps1) to ''New'' context menu'
    Registry    = @(
        @{ Path = 'HKCR\.ps1\ShellNew'; Name = 'NullFile'; Type = 'String'; Data = '' }
        @{ Path = 'HKCR\Microsoft.PowerShellScript.1'; Name = 'FriendlyTypeName'; Type = 'String'; Data = 'Windows PowerShell Script' }
    )
    # The default ('') values cannot be expressed in the Registry schema (a value name
    # is required), so they are written by the companion script.
    Script      = 'new-ps1.ps1'
}
