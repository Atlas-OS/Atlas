---
title: Disable Microsoft Store Recommended Search Results
description: Disables recommended Microsoft Store apps in Start Menu
actions:
  - !powerShell:
    command: '& (Join-Path ([Environment]::GetFolderPath(''Windows'')) ''AtlasModules\Scripts\Tasks\Disable-StoreSearchRecommendations.ps1'')'
    runas: currentUserElevated
    wait: true
