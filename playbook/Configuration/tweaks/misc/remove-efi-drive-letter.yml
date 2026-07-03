---
title: Removes the drive letter from the EFI partition.
description: This happens after clean install without formatting the drive
actions:
  - !powerShell:
    command: '& (Join-Path ([Environment]::GetFolderPath(''Windows'')) ''AtlasModules\Scripts\Tasks\Remove-EfiDriveLetter.ps1'')'
    wait: true
    runas: currentUserElevated
