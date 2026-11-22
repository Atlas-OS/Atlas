@{
    Name        = 'Disable Reserved Storage'
    Description = 'Turns off the reserved storage Windows keeps for updates, which frees that disk space.'
    Run         = @(
        @{ Exe = '{windir}\System32\dism.exe'; Args = @('/Online', '/Set-ReservedStorageState', '/State:Disabled'); AllowedExitCodes = @(0, 3010); IgnoreErrors = $true }
    )
}
