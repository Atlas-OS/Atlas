# Companion of enable-notifications.psd1.
# Set-NotificationState.ps1 writes its per-user values into every loaded user hive, so it
# is correct under TrustedInstaller.
$ErrorActionPreference = 'Stop'
& (Join-Path -Path ([Environment]::GetFolderPath('Windows')) -ChildPath 'AtlasModules\Scripts\Internal\Set-NotificationState.ps1') -Mode Enable
