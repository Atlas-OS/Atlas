---
title: Delete Windows-version Specific Tweaks
description: Deletes Windows 10 or Windows 11-only tweaks in the Atlas folder, depending on the current version
actions:
    # Delete ARM-specific files
    # FTH files (which are also non-ARM) are deleted in its own YML
  - !powerShell:
    command: '& (Join-Path ([Environment]::GetFolderPath(''Windows'')) ''AtlasModules\Scripts\Tasks\Remove-VersionSpecificAtlasFiles.ps1'')'
    wait: true
    cpuArch: 'Arm64'
