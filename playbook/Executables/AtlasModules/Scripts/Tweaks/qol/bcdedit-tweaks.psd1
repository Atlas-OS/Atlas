@{
    Name        = 'Configure Boot Configuration'
    Description = 'Configures the boot configuration (BCD) for QoL'
    # ------------------------------------------------------------------------------- #
    # https://learn.microsoft.com/en-us/windows-hardware/drivers/devtest/bcdedit--set #
    # ------------------------------------------------------------------------------- #
    Run         = @(
        # Lowering dual boot choice time
        @{ Exe = 'bcdedit.exe'; Args = '/timeout 10' }
        # Use legacy boot menu
        # Faster as it doesn't boot into an OS
        @{ Exe = 'bcdedit.exe'; Args = '/set bootmenupolicy legacy' }
    )
}
