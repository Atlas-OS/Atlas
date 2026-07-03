---
title: Disable Cross Device Resume
description: Disables the CrossDeviceResume process
builds: [ '>=22000' ]
actions:
  - !registryValue: 
    path: 'HKCU\Software\Microsoft\Windows\CurrentVersion\CrossDeviceResume\Configuration'
    value: 'IsResumeAllowed'
    type: REG_DWORD
    data: '0'
    
  - !registryValue: 
    path: 'HKCU\SOFTWARE\Microsoft\PolicyManager\default\Connectivity\DisableCrossDeviceResume'
    value: 'Value'
    type: REG_DWORD
    data: '1'
    


