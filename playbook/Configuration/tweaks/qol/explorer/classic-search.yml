---
title: Disable Legacy File Explorer Search Redirect
description: Removes the legacy File Explorer search COM redirect to prevent Explorer runtime errors on newer Windows builds
actions:
  - !registryKey: {path: 'HKLM\SOFTWARE\Classes\CLSID\{1d64637d-31e9-4b06-9124-e83fb178ac6e}\TreatAs', operation: delete}
  - !registryKey: {path: 'HKLM\SOFTWARE\Classes\WOW6432Node\CLSID\{1d64637d-31e9-4b06-9124-e83fb178ac6e}\TreatAs', operation: delete}
  - !registryKey: {path: 'HKLM\SOFTWARE\WOW6432Node\Classes\CLSID\{1d64637d-31e9-4b06-9124-e83fb178ac6e}\TreatAs', operation: delete}
  - !registryKey: {path: 'HKCU\Software\Classes\CLSID\{1d64637d-31e9-4b06-9124-e83fb178ac6e}\TreatAs', operation: delete}
  - !registryKey: {path: 'HKCU\Software\Classes\WOW6432Node\CLSID\{1d64637d-31e9-4b06-9124-e83fb178ac6e}\TreatAs', operation: delete}
