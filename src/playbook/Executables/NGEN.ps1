# speeds up powershell startup time by 10x
$env:path = "$([Runtime.InteropServices.RuntimeEnvironment]::GetRuntimeDirectory());" + $env:path
[AppDomain]::CurrentDomain.GetAssemblies().Location | ? {$_} | % {
    Write-Host "NGENing: $(Split-Path $_ -Leaf)" -ForegroundColor Yellow
    ngen install $_ | Out-Null
}