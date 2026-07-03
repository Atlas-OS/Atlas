@{
    Name        = 'Disable Reserved Storage'
    Description = 'Disables reserved storage for Windows Updates to have more storage space'
    Run         = @(
        @{ Exe = 'DISM.exe'; Args = '/Online /Set-ReservedStorageState /State:Disabled'; IgnoreErrors = $true }
    )
}
