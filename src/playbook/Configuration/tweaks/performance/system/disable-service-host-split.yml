---
title: Disable Service Host Splitting
description: Disables Service Host splitting for much lower RAM usage and process count, excluding XBOX services to fix issues with Game Bar
actions:
  # https://learn.microsoft.com/en-us/windows/application-management/svchost-service-refactoring
  - !powerShell:
    command: '& (Join-Path ([Environment]::GetFolderPath(''Windows'')) ''AtlasModules\Scripts\Tasks\Disable-ServiceHostSplit.ps1'')'
    wait: true
