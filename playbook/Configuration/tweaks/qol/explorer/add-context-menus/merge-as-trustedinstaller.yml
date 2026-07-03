---
title: Add 'Merge as TrustedInstaller' to Context Menu
description: Adds 'Merge as TrustedInstaller' to context menu for registry files
actions:
  - !registryValue:
    path: 'HKLM\Software\Classes\regfile\Shell\RunAs'
    value: ''
    data: 'Merge As TrustedInstaller'
    type: REG_SZ
  - !registryValue:
    path: 'HKLM\Software\Classes\regfile\Shell\RunAs'
    value: 'HasLUAShield'
    data: '1'
    type: REG_SZ
  - !registryValue:
    path: 'HKLM\Software\Classes\regfile\Shell\RunAs\Command'
    value: ''
    data: 'cmd /c "%windir%\AtlasModules\Scripts\RunAsTI.cmd" "%1"'
    type: REG_SZ
