---
title: Disable MSRT telemetry
description: Disables MSRT's (Malicious Software Removal Tool) telemetry features
actions:
    # Disable MSRT telemetry
  - !registryValue: {path: 'HKLM\SOFTWARE\Policies\Microsoft\MRT', value: 'DontReportInfectionInformation', type: REG_DWORD, data: '1'}
  - !registryValue: {path: 'HKLM\SOFTWARE\Microsoft\RemovalTools\MpGears', value: 'HeartbeatTrackingIndex', type: REG_DWORD, data: '0'}
  - !registryValue: {path: 'HKLM\SOFTWARE\Microsoft\RemovalTools\MpGears', value: 'SpyNetReportingLocation', type: REG_MULTI_SZ, data: ''}
