---
title: Disable Core Isolation
description: Disables Core Isolation (VBS) based on the user's options
option: 'disable-core-isolation'
actions:
  - !powerShell:
    command: '& """.\AtlasModules\Scripts\ScriptWrappers\ConfigVBS.ps1""" -DisableAllVBS'
    wait: true
    exeDir: true
