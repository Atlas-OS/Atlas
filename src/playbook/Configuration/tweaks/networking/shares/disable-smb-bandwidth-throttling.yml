---
title: Disable SMB Bandwidth Throttling
description: Disables SMB bandwidth throttling for improved performance
actions:
  # https://learn.microsoft.com/en-us/windows-server/administration/performance-tuning/role/file-server
  - !registryValue:
    path: 'HKLM\SYSTEM\CurrentControlSet\Services\LanmanWorkstation\Parameters'
    value: 'DisableBandwidthThrottling'
    data: '1'
    type: REG_DWORD
