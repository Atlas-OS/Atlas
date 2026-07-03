# Blocks the Microsoft Store search database (store.db) so recommended Store apps do
# not appear in Start Menu search.
# NOTE: the tweak engine runs this in the installer's (TrustedInstaller) context, so
# the deployed task script resolves LocalApplicationData for that context.
$ErrorActionPreference = 'Stop'

& (Join-Path -Path ([Environment]::GetFolderPath('Windows')) -ChildPath 'AtlasModules\Scripts\Tasks\Disable-StoreSearchRecommendations.ps1')
