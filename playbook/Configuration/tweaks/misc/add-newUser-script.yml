---
title: Add newUsers.ps1 script
description: Adds the newUsers.ps1 script to RunOnce, which applies any tweaks that are dynamically generated on new user creation
actions:
  - !powerShell:
    command: |
      $markerPath = 'HKLM:\SOFTWARE\AtlasOS\UserSetup'
      $null = New-Item -Path $markerPath -Force
      $acl = Get-Acl -Path $markerPath
      $users = New-Object System.Security.Principal.SecurityIdentifier 'S-1-5-32-545'
      $rule = New-Object System.Security.AccessControl.RegistryAccessRule(
        $users,
        [System.Security.AccessControl.RegistryRights]'ReadKey, SetValue',
        [System.Security.AccessControl.AccessControlType]::Allow
      )
      $acl.SetAccessRule($rule)
      Set-Acl -Path $markerPath -AclObject $acl
    wait: true
  - !registryValue:
    path: 'HKU\AME_UserHive_Default\SOFTWARE\Microsoft\Windows\CurrentVersion\RunOnce'
    value: 'RunScript'
    data: |
      powershell -EP RemoteSigned -NoP & """$([Environment]::GetFolderPath('Windows'))\AtlasModules\Scripts\newUsers.ps1"""
    type: REG_SZ
  - !registryValue:
    path: 'HKU\AME_UserHive_Default\SOFTWARE\Microsoft\Windows\CurrentVersion\Search'
    value: 'SearchboxTaskbarMode'
    data: '1'
    type: REG_DWORD
  - !registryValue:
    path: 'HKU\AME_UserHive_Default\SOFTWARE\Microsoft\Windows\CurrentVersion\Search'
    value: 'SearchboxTaskbarModeCache'
    data: '1'
    type: REG_DWORD
