@{
    Name        = 'Configure Boot Configuration'
    Description = 'Uses the legacy boot menu, which appears before Windows starts loading, and sets its timeout to 10 seconds.'
    # https://learn.microsoft.com/windows-hardware/drivers/devtest/bcdedit--set
    Run         = @(
        @{ Exe = '{windir}\System32\bcdedit.exe'; Args = @('/timeout', '10') }
        # Faster as it doesn't boot into an OS
        @{ Exe = '{windir}\System32\bcdedit.exe'; Args = @('/set', 'bootmenupolicy', 'legacy') }
    )
}
