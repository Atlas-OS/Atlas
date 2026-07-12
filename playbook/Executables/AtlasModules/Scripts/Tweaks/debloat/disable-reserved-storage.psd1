@{
    Name        = 'Disable Reserved Storage'
    Description = 'Disables reserved storage for Windows Updates to have more storage space'
    Run         = @(
        @{ Exe = '{windir}\System32\dism.exe'; Args = @('/Online', '/Set-ReservedStorageState', '/State:Disabled'); AllowedExitCodes = @(0, 3010); IgnoreErrors = $true }
    )
}
