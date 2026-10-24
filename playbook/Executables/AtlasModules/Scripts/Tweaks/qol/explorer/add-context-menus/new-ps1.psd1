@{
    Name        = 'Add PowerShell Script to ''New'' Context Menu'
    Description = 'Adds PowerShell script (.ps1) to ''New'' context menu'
    Registry    = @(
        @{ Path = 'HKCR\.ps1'; Name = ''; Type = 'String'; Data = 'Microsoft.PowerShellScript.1' }
        @{ Path = 'HKCR\.ps1\ShellNew'; Name = 'NullFile'; Type = 'String'; Data = '' }
        @{ Path = 'HKCR\Microsoft.PowerShellScript.1'; Name = ''; Type = 'String'; Data = 'Windows PowerShell Script' }
        @{ Path = 'HKCR\Microsoft.PowerShellScript.1'; Name = 'FriendlyTypeName'; Type = 'String'; Data = 'Windows PowerShell Script' }
    )
}
