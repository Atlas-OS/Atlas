# Companion of add-music-videos-to-home.psd1 (RunAs = User): re-pins Music & Videos to
# File Explorer Home. Runs in the interactive user's session, so the Shell COM verb reaches
# the running explorer. The logic lives in a Task script so it can also be reused elsewhere.
$ErrorActionPreference = 'Stop'

& (Join-Path -Path ([Environment]::GetFolderPath('Windows')) -ChildPath 'AtlasModules\Scripts\Tasks\Add-MusicVideosToHome.ps1')
