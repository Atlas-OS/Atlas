# Run only against an explicit request prepared in target/iso-validation.
# Elevation is supplied by the caller. This builds media; it never installs Atlas.
$ErrorActionPreference = 'Stop'
$root = [IO.Path]::GetFullPath((Join-Path $PSScriptRoot '..\target\iso-validation'))
$resource = [IO.Path]::GetFullPath((Join-Path $PSScriptRoot '..\resources\iso'))
$exitFile = Join-Path $root 'exit-code.txt'
# A previous successful build must not look like the result of a running one.
if (Test-Path -LiteralPath $exitFile) { Remove-Item -LiteralPath $exitFile -Force }
Copy-Item -LiteralPath (Join-Path $resource 'Setup.ps1') -Destination $root -Force
Copy-Item -LiteralPath (Join-Path $resource 'Desktop.ps1') -Destination $root -Force
Copy-Item -LiteralPath (Join-Path $resource 'Network-Drivers.ps1') -Destination $root -Force
$request = Get-Content -LiteralPath (Join-Path $root 'request.json') -Raw | ConvertFrom-Json
$policyName = if ($request.drivers -eq 'manual') { 'Disable' } else { 'Enable' }
Copy-Item -LiteralPath (Join-Path $PSScriptRoot "..\..\playbook\Executables\AtlasDesktop\2. Drivers\Drivers from Windows Update\$policyName Drivers from Windows Update.reg") -Destination (Join-Path $root 'DriverPolicy.reg') -Force
$arguments = '-NoLogo -NoProfile -NonInteractive -ExecutionPolicy Bypass -File "' + (Join-Path $resource 'Build-Iso.ps1') + '" -Operation Build -RequestFile "' + (Join-Path $root 'request.json') + '"'
$child = Start-Process -FilePath (Join-Path $env:WINDIR 'System32\WindowsPowerShell\v1.0\powershell.exe') -ArgumentList $arguments -Wait -PassThru -WindowStyle Hidden -RedirectStandardOutput (Join-Path $root 'worker.log') -RedirectStandardError (Join-Path $root 'worker-error.log')
$child.ExitCode | Set-Content -LiteralPath $exitFile
exit $child.ExitCode
