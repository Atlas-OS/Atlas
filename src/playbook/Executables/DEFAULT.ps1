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

    if ($state.state -eq 1 -or $state.state -ne 0) {
        $scriptPath = $path.path
        if (Test-Path $scriptPath) {
            Write-Host "Running: $scriptPath" -ForegroundColor Cyan
            & $scriptPath /silent
        } else {
            Write-Host "Script not found: $scriptPath" -ForegroundColor Red
        }
    }
}
