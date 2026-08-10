param (
    [bool]$Silent = $false
)

$ErrorActionPreference = 'Stop'

function Stop-TaskManager {
    $processes = Get-CimInstance Win32_Process -Filter "Name = 'taskmgr.exe'" -ErrorAction SilentlyContinue
    if ($processes) {
        foreach ($process in $processes) {
            Stop-Process -Id $process.ProcessId -Force -ErrorAction SilentlyContinue
        }
    }

    & taskkill.exe /F /IM taskmgr.exe 2>$null
    $exitCode = $LASTEXITCODE
    if ($exitCode -ne 0 -and $exitCode -ne 128) {
        throw "taskkill.exe failed while closing taskmgr.exe with exit code $exitCode."
    }
}

$uninstallScript = Join-Path -Path ([Environment]::GetFolderPath('Windows')) -ChildPath 'AtlasDesktop\6. Advanced Configuration\Process Explorer\Uninstall Process Explorer.cmd'
Stop-TaskManager

if (Test-Path -LiteralPath $uninstallScript -PathType Leaf) {
    Start-Process -FilePath $uninstallScript -ArgumentList '/silent' -WindowStyle Hidden -Wait
}
else {
    Write-Warning "Process Explorer uninstall script '$uninstallScript' was not found; continuing upgrade cleanup."
}

Stop-TaskManager
