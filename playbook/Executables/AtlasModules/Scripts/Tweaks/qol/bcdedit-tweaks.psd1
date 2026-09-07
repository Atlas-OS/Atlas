@{
    Name        = 'Configure Boot Configuration'
    Description = 'Configures the boot configuration (BCD) for QoL'
    # https://learn.microsoft.com/en-us/windows-hardware/drivers/devtest/bcdedit--set
    Run         = @(
        @{ Exe = '{windir}\System32\bcdedit.exe'; Args = @('/timeout', '10') }
        # Faster as it doesn't boot into an OS
        @{ Exe = '{windir}\System32\bcdedit.exe'; Args = @('/set', 'bootmenupolicy', 'legacy') }
    )
}
