---
title: Configure PowerShell
description: Configures PowerShell for the optimal privacy and usability
actions:
    # Disable PowerShell Core telemetry
  - !cmd: {command: 'setx POWERSHELL_TELEMETRY_OPTOUT 1'}

    # Set PowerShell execution policy to Unrestricted temporarily during installation
    # This allows all Atlas installation scripts to run without signature verification
    # At the end of installation, this will be changed to RemoteSigned for better security
    # RemoteSigned allows local Atlas folder scripts to run while requiring signatures for downloaded scripts
  - !registryValue:
    path: 'HKLM\SOFTWARE\Microsoft\PowerShell\1\ShellIds\Microsoft.PowerShell'
    value: 'ExecutionPolicy'
    data: 'Unrestricted'
    type: REG_SZ
