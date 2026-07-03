$registryPath = 'HKLM:\SOFTWARE\AtlasOS\Services'

if (-not (Test-Path $registryPath)) {
    Write-Host "Registry path '$registryPath' not found, skipping." -ForegroundColor Yellow
    exit 0
}

Get-ChildItem -Path $registryPath | ForEach-Object {
    $subkey = $_
    $state = Get-ItemProperty -Path $subkey.PSPath -Name 'state' -ErrorAction SilentlyContinue
    $path  = Get-ItemProperty -Path $subkey.PSPath -Name 'path'  -ErrorAction SilentlyContinue

    if ($null -eq $state -or $null -eq $path) { return }

    $scriptPath = $path.path

    if (-not (Test-Path $scriptPath)) {
        Write-Host "Script not found, cleaning up obsolete registry key: $scriptPath" -ForegroundColor Yellow
        Remove-Item -Path $subkey.PSPath -Force -Recurse -ErrorAction SilentlyContinue
        return
    }

    if ($state.state -eq 1 -or $state.state -ne 0) {
        Write-Host "Running: $scriptPath" -ForegroundColor Cyan
        if ($scriptPath -like '*.ps1') {
            & $scriptPath -Silent
        } else {
            & $scriptPath /silent
        }
    }
}
