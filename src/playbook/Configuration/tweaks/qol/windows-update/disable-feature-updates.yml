---
title: Disable Feature Updates
description: Disables feature updates as they might reset tweaks, bring back bloatware and potentially break the system.
actions:
  # - !registryValue: {path: 'HKLM\SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate', value: 'DeferFeatureUpdates', data: '1', type: REG_DWORD}
  # - !registryValue: {path: 'HKLM\SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate', value: 'DeferFeatureUpdatesPeriodInDays', data: '365', type: REG_DWORD}
    # https://admx.help/?Category=Windows_11_2022&Policy=Microsoft.Policies.WindowsUpdate::TargetReleaseVersion
  - !registryValue: {path: 'HKLM\SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate', value: 'TargetReleaseVersion', data: '1', type: REG_DWORD}
  - !powerShell:
    command: '& (Join-Path ([Environment]::GetFolderPath(''Windows'')) ''AtlasModules\Scripts\Tasks\Set-FeatureUpdateTarget.ps1'')'
    wait: true
