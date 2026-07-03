# speeds up powershell startup time by 10x
Set-StrictMode -Version 3.0

$env:path = "$([Runtime.InteropServices.RuntimeEnvironment]::GetRuntimeDirectory());" + $env:path
[AppDomain]::CurrentDomain.GetAssemblies().Location | Where-Object { $_ } | ForEach-Object {
    Write-Host "NGENing: $(Split-Path $_ -Leaf)" -ForegroundColor Yellow
    ngen install $_ | Out-Null
}
