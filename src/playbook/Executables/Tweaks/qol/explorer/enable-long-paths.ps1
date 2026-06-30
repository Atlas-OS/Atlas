---
title: Enable Long Paths
description: Disables the default path length limit.
actions:
  - !registryValue:
    path: 'HKLM\SYSTEM\CurrentControlSet\Control\FileSystem'
    value: 'LongPathsEnabled'
    data: '1'
    type: REG_DWORD
