---
title: Disable Background Apps
description: Disables background apps so there's minimal resources used in the background
actions:
  - !registryValue:
    path: 'HKCU\SOFTWARE\Microsoft\Windows\CurrentVersion\BackgroundAccessApplications'
    value: 'GlobalUserDisabled'
    data: '1'
    type: REG_DWORD
    
  - !registryValue:
    path: 'HKCU\SOFTWARE\Microsoft\Windows\CurrentVersion\Search'
    value: 'BackgroundAppGlobalToggle'
    data: '0'
    type: REG_DWORD
    
