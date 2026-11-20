@{
    Name        = 'Configure Time Servers'
    Description = 'Uses the pool.ntp.org time servers, which are more reliable and accurate than the Windows default.'
    # The servers are plain registry values, so they apply even where Windows Time is
    # disabled. Starting the service and telling it to reload only warn on failure: PCs
    # tweaked beyond Atlas can have Windows Time turned off.
    Registry    = @(
        # https://www.pool.ntp.org/en/use.html; what w32tm /syncfromflags:manual /manualpeerlist writes.
        @{ Path = 'HKLM\SYSTEM\CurrentControlSet\Services\W32Time\Parameters'; Name = 'NtpServer'; Type = 'String'; Data = '0.pool.ntp.org 1.pool.ntp.org 2.pool.ntp.org 3.pool.ntp.org'; SkipVerification = 'A time server the user picks later is their choice, not drift.' }
        @{ Path = 'HKLM\SYSTEM\CurrentControlSet\Services\W32Time\Parameters'; Name = 'Type'; Type = 'String'; Data = 'NTP'; SkipVerification = 'A time source the user picks later is their choice, not drift.' }
    )
    Services    = @(
        @{ Name = 'w32time'; Operation = 'Start'; IgnoreErrors = $true }
    )
    Run         = @(
        @{ Exe = '{windir}\System32\w32tm.exe'; Args = @('/config', '/update'); IgnoreErrors = $true }
        @{ Exe = '{windir}\System32\w32tm.exe'; Args = @('/resync'); IgnoreErrors = $true }
    )
}
