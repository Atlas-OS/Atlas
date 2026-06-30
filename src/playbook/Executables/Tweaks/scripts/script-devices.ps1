---
title: Disable Devices
description: Disables devices that users would not typically need to reduce any potential system resources usage in the background
actions:
  - !powerShell:
    command: |
      Get-NetAdapterBinding -Name "*" -ComponentID ms_msclient, ms_server, ms_lldp, ms_lltdio, ms_rspndr -ErrorAction SilentlyContinue |
        Disable-NetAdapterBinding -ErrorAction SilentlyContinue |
        Out-Null
  - !powerShell:
    command: '.\DISABLEPNP.ps1'
    exeDir: true
    wait: true
