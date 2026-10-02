# Builds media from the hand-written request in target/iso-validation, running the
# worker from that job folder as the app does. The caller supplies elevation;
# nothing is installed.
$ErrorActionPreference = 'Stop'
$root = [IO.Path]::GetFullPath((Join-Path $PSScriptRoot '..\target\iso-validation'))
$resource = [IO.Path]::GetFullPath((Join-Path $PSScriptRoot '..\resources\iso'))
$compatibility = [IO.Path]::GetFullPath((Join-Path $PSScriptRoot '..\..\playbook\Executables\AtlasModules\Scripts\Compatibility'))
$exitFile = Join-Path $root 'exit-code.txt'
# A previous successful build must not look like the result of a running one.
if (Test-Path -LiteralPath $exitFile) { Remove-Item -LiteralPath $exitFile -Force }
foreach ($name in @('Build-Iso.ps1', 'Master-Iso.ps1', 'Setup.ps1', 'Desktop.ps1', 'Desktop-Policy.ps1', 'Network-Drivers.ps1')) {
    Copy-Item -LiteralPath (Join-Path $resource $name) -Destination $root -Force
}
foreach ($name in @('Windows-Release.ps1', 'windows-releases.json')) {
    Copy-Item -LiteralPath (Join-Path $compatibility $name) -Destination $root -Force
}
Copy-Item -LiteralPath (Join-Path $compatibility '..\Preparation\RegistryFile.ps1') -Destination (Join-Path $root 'RegistryFile.ps1') -Force
$request = [IO.File]::ReadAllText((Join-Path $root 'request.json')) | ConvertFrom-Json
$policyName = if ($request.drivers -eq 'manual') { 'Disable' } else { 'Enable' }
Copy-Item -LiteralPath (Join-Path $PSScriptRoot "..\..\playbook\Executables\AtlasDesktop\2. Drivers\Drivers from Windows Update\$policyName Drivers from Windows Update.reg") -Destination (Join-Path $root 'DriverPolicy.reg') -Force
# The media carries the notices the app itself includes. The app exports them
# only to a new file, so remove a copy left by an earlier run first.
$notices = Join-Path $root 'THIRD-PARTY-NOTICES.txt'
if (Test-Path -LiteralPath $notices) { Remove-Item -LiteralPath $notices -Force }
$app = [string]$request.app
if ($app.StartsWith('\\?\UNC\')) { $app = '\\' + $app.Substring(8) }
elseif ($app.StartsWith('\\?\')) { $app = $app.Substring(4) }
$export = Start-Process -FilePath $app -ArgumentList @('--licenses', "`"$notices`"") -Wait -PassThru -WindowStyle Hidden
if ($export.ExitCode -ne 0) { throw "Atlas Manager could not export its licence notices (exit code $($export.ExitCode))." }
$arguments = '-NoLogo -NoProfile -NonInteractive -ExecutionPolicy Bypass -File "' + (Join-Path $root 'Build-Iso.ps1') + '" -Operation Build -RequestFile "' + (Join-Path $root 'request.json') + '"'
$child = Start-Process -FilePath (Join-Path $env:WINDIR 'System32\WindowsPowerShell\v1.0\powershell.exe') -ArgumentList $arguments -Wait -PassThru -WindowStyle Hidden -RedirectStandardOutput (Join-Path $root 'worker.log') -RedirectStandardError (Join-Path $root 'worker-error.log')
$child.ExitCode | Set-Content -LiteralPath $exitFile
exit $child.ExitCode
