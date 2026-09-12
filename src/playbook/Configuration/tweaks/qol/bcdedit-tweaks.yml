---
title: Configure Boot Configuration
description: Configures the boot configuration (BCD) for QoL
actions:
  # ------------------------------------------------------------------------------- #
  # https://learn.microsoft.com/en-us/windows-hardware/drivers/devtest/bcdedit--set #
  # ------------------------------------------------------------------------------- #

    # Lowering dual boot choice time
  - !run: {exe: 'bcdedit', args: '/timeout 10'}

    # Use legacy boot menu
    # Faster as it doesn't boot into an OS
  - !run: {exe: 'bcdedit', args: '/set bootmenupolicy legacy'}
