$ErrorActionPreference = 'Stop'

$localAppData = [Environment]::GetFolderPath('LocalApplicationData')
if ([string]::IsNullOrWhiteSpace($localAppData)) {
    throw 'LocalApplicationData is not available for the current user.'
}

$storeDb = Join-Path -Path $localAppData -ChildPath 'Packages\Microsoft.WindowsStore_8wekyb3d8bbwe\LocalState\store.db'
$storeDbParent = Split-Path -Path $storeDb -Parent

New-Item -Path $storeDbParent -ItemType Directory -Force | Out-Null
if (-not (Test-Path -LiteralPath $storeDb -PathType Leaf)) {
    New-Item -Path $storeDb -ItemType File -Force | Out-Null
}

$denyRule = '*S-1-1-0:F'
& icacls.exe $storeDb /deny $denyRule | Out-Null
if ($LASTEXITCODE -ne 0) {
    throw "icacls.exe failed to deny Store DB access on '$storeDb' with exit code $LASTEXITCODE."
}
