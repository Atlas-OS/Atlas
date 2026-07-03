$ErrorActionPreference = 'Stop'

$uninstallScript = Join-Path -Path ([Environment]::GetFolderPath('Windows')) -ChildPath 'AtlasDesktop\6. Advanced Configuration\Process Explorer\Uninstall Process Explorer.cmd'
if (Test-Path -LiteralPath $uninstallScript -PathType Leaf) {
    Start-Process -FilePath $uninstallScript -ArgumentList '/silent' -WindowStyle Hidden
}
else {
    Write-Warning "Process Explorer uninstall script '$uninstallScript' was not found; continuing upgrade cleanup."
}

& taskkill.exe /IM taskmgr.exe 2>$null
$exitCode = $LASTEXITCODE
if ($exitCode -ne 0 -and $exitCode -ne 128) {
    throw "taskkill.exe failed while closing taskmgr.exe with exit code $exitCode."
}
