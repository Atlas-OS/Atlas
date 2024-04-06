---
title: Disable Key Management System Telemetry
description: Turns off KMS client online AVS validation, which prevents from sending data to Microsoft regardless of its activation state, for privacy
actions:
    # https://admx.help/?Category=Windows_11_2022&Policy=Microsoft.Policies.SoftwareProtectionPlatform::NoAcquireGT
  - !registryValue:
    path: 'HKLM\SOFTWARE\Policies\Microsoft\Windows NT\CurrentVersion\Software Protection Platform'
    value: 'NoGenTicket'
    data: '1'
    type: REG_DWORD
