@{
    Name        = 'Configure Time Servers'
    Description = 'Configures time servers to be more reliable and accurate than the defaults'
    Services    = @(
        # https://www.pool.ntp.org/en/use.html
        @{ Name = 'w32time'; Operation = 'Start' }
    )
    Run         = @(
        @{ Exe = '{windir}\System32\w32tm.exe'; Args = @('/config', '/syncfromflags:manual', '/manualpeerlist:0.pool.ntp.org 1.pool.ntp.org 2.pool.ntp.org 3.pool.ntp.org') }
        @{ Exe = '{windir}\System32\w32tm.exe'; Args = @('/config', '/update') }
        @{ Exe = '{windir}\System32\w32tm.exe'; Args = @('/resync'); IgnoreErrors = $true }
    )
}
