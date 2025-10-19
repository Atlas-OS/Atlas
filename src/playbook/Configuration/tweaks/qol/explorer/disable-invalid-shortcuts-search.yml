---
title: Disable Searching for Invalid Shortcuts
description: Disables searching drives or using NTFS file system tracking for shortcuts that have invalid/non-existent paths for responsiveness
actions:
  - !registryValue:
    path: 'HKCU\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\Explorer'
    value: 'NoResolveSearch'
    data: '1'
    type: REG_DWORD


  - !registryValue:
    path: 'HKCU\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\Explorer'
    value: 'NoResolveTrack'
    data: '1'
    type: REG_DWORD
