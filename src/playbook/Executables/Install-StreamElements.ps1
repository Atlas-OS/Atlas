[CmdletBinding()]
param()

$ErrorActionPreference = 'Stop'

[Net.ServicePointManager]::SecurityProtocol = [Net.ServicePointManager]::SecurityProtocol -bor [Net.SecurityProtocolType]::Tls12

# StreamElements SE.Live is an OBS plugin distributed as an NSIS installer
# (obs-streamelements-setup.exe). It installs silently with /S, but OBS Studio
# must already be present for the plugin to be usable.
$downloadUrl = 'https://strms.net/selivedownload'

Write-Output 'Ensuring OBS Studio is installed (SE.Live is an OBS plugin)...'
$obsFound = $false
$obsPaths = @(
    Join-Path $env:ProgramFiles 'obs-studio\bin\64bit\obs64.exe',
    Join-Path ${env:ProgramFiles(x86)} 'obs-studio\bin\64bit\obs64.exe',
    Join-Path $env:LOCALAPPDATA 'Programs\obs-studio\bin\64bit\obs64.exe'
)
foreach ($p in $obsPaths) { if (Test-Path $p) { $obsFound = $true; break } }
if (-not $obsFound) {
    Write-Output 'OBS not found; installing via winget...'
    winget install --exact --id OBSProject.OBSStudio --silent --accept-package-agreements --accept-source-agreements --source winget | Out-Null
} else {
    Write-Output 'OBS already present.'
}

$work = Join-Path $env:TEMP ('StreamElements_' + [guid]::NewGuid().ToString('N'))
New-Item -ItemType Directory -Force -Path $work | Out-Null
$exe = Join-Path $work 'obs-streamelements-setup.exe'

Write-Output "Downloading SE.Live from $downloadUrl ..."
Invoke-WebRequest -Uri $downloadUrl -OutFile $exe -UseBasicParsing -MaximumRedirection 10 -TimeoutSec 300 -Headers @{ 'User-Agent' = 'EBOS-Playbook' }

# Sanity check: must be a PE executable
$bytes = [System.IO.File]::ReadAllBytes($exe)
if ($bytes.Length -lt 2 -or $bytes[0] -ne 0x4D -or $bytes[1] -ne 0x5A) {
    throw 'Downloaded file is not a valid executable.'
}

Write-Output "Running silent install: $exe /S"
$proc = Start-Process -FilePath $exe -ArgumentList '/S' -Wait -PassThru -NoNewWindow
Write-Output "Setup exited with code $($proc.ExitCode)"

Remove-Item $work -Recurse -Force -ErrorAction SilentlyContinue
exit 0
