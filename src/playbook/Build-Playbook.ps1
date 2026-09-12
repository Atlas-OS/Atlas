<#
.SYNOPSIS
  Self-contained EBOS playbook builder. Replaces the external
  ..\dependencies\local-build.ps1 dependency.
  Packages Configuration/, Executables/, Images/, playbook.conf,
  playbook.png (+ this build script for parity with old .apbx) into
  "EBOS Release.apbx" (a ZIP renamed to .apbx).
#>
[CmdletBinding()]
param(
  [string]$FileName = 'EBOS Release',
  [switch]$NoPause
)

$ErrorActionPreference = 'Stop'
$repoRoot = Split-Path $PSScriptRoot -Parent
if (-not $repoRoot -or -not (Test-Path $repoRoot)) { $repoRoot = $PSScriptRoot }
# When invoked from Executables/ dir layout, P -Parent handling differs;
# normalize: this script lives in repo root alongside build-playbook.cmd.
if (Test-Path (Join-Path $PSScriptRoot 'playbook.conf')) { $repoRoot = $PSScriptRoot }

Write-Host "Building Playbook from $repoRoot ..." -ForegroundColor Cyan

# 1. Regenerate playbook.ico from playbook.png so the packaged icon is fresh.
$iconScript = Join-Path $repoRoot 'Executables\Set-ApbkIcon.ps1'
if (Test-Path $iconScript) {
  Write-Host 'Regenerating playbook.ico ...' -ForegroundColor Cyan
  & "$env:SystemRoot\System32\WindowsPowerShell\v1.0\powershell.exe" -NoProfile -ExecutionPolicy Bypass -File $iconScript
} else {
  Write-Warning "Icon script not found: $iconScript"
}

# 2. Validate required inputs.
$required = @('Configuration', 'Executables', 'Images', 'playbook.conf', 'playbook.png')
foreach ($r in $required) {
  if (-not (Test-Path (Join-Path $repoRoot $r))) { throw "Required playbook input missing: $r" }
}
if (-not (Test-Path (Join-Path $repoRoot 'Configuration\custom.yml'))) { throw 'Configuration\custom.yml missing' }
if (-not (Test-Path (Join-Path $repoRoot 'Configuration\tweaks.yml'))) { throw 'Configuration\tweaks.yml missing' }

# 2b. Single source of truth for the EBOS version: <Version> in playbook.conf.
# Files reference it via the %%EBOS_VERSION%% token (see config-oem-information.yml,
# ebos-final-fixes.yml, Verify-EBOS.ps1); the token is injected during staging below.
[xml]$confXml = Get-Content (Join-Path $repoRoot 'playbook.conf') -Raw
$ebosVersion = $confXml.Playbook.Version
if ([string]::IsNullOrWhiteSpace($ebosVersion)) { throw 'Could not read <Version> from playbook.conf' }
Write-Host "EBOS version: $ebosVersion" -ForegroundColor Cyan

# 3. Stage file list (match legacy .apbx layout observed via tar -tf).
$outFile = Join-Path $repoRoot ("$FileName.apbx")
if (Test-Path $outFile) {
  Write-Host "Removing old $outFile ..." -ForegroundColor Yellow
  Remove-Item -LiteralPath $outFile -Force
}

$stage = Join-Path ([IO.Path]::GetTempPath()) ('ebos-apbx-' + [guid]::NewGuid().ToString('N'))
New-Item -ItemType Directory -Path $stage -Force | Out-Null
try {
  foreach ($item in @('build-playbook.cmd', 'Build-Playbook.ps1', 'Configuration', 'Executables', 'Images', 'playbook.conf', 'playbook.png')) {
    $src = Join-Path $repoRoot $item
    if (Test-Path $src) {
      Copy-Item -Path $src -Destination (Join-Path $stage $item) -Recurse -Force
    } elseif ($item -in @('build-playbook.cmd', 'Build-Playbook.ps1')) {
      Write-Warning "Optional file skipped (not found): $item"
    } else {
      throw "Required input vanished during staging: $item"
    }
  }

  # Exclude any nested .apbx that may have been copied via Executables/ or root
  Get-ChildItem -Path $stage -Recurse -Filter '*.apbx' -ErrorAction SilentlyContinue | Remove-Item -Force -ErrorAction SilentlyContinue

  # Inject the version token (only files containing it are touched, so
  # encodings like the UTF-16 DEFAULT.reg are never rewritten).
  # The builder itself is excluded: it only mentions the token in its own
  # search pattern, which must stay literal.
  $tokenFiles = Get-ChildItem -Path $stage -Recurse -File -Include '*.yml', '*.ps1', '*.cmd', '*.xml' -ErrorAction SilentlyContinue |
    Where-Object { $_.Name -notin @('Build-Playbook.ps1', 'build-playbook.cmd') } |
    Where-Object { (Get-Content -LiteralPath $_.FullName -Raw -Encoding UTF8 -ErrorAction SilentlyContinue) -match '%%EBOS_VERSION%%' }
  foreach ($tf in $tokenFiles) {
    $content = Get-Content -LiteralPath $tf.FullName -Raw -Encoding UTF8
    $content = $content -replace '%%EBOS_VERSION%%', $ebosVersion
    # Preserve a UTF-16 file if it had a BOM (defensive; token files are ASCII).
    $bytes = [IO.File]::ReadAllBytes($tf.FullName)
    if ($bytes.Length -ge 2 -and $bytes[0] -eq 0xFF -and $bytes[1] -eq 0xFE) {
      [IO.File]::WriteAllText($tf.FullName, $content, [Text.Encoding]::Unicode)
    } else {
      [IO.File]::WriteAllText($tf.FullName, $content, (New-Object Text.UTF8Encoding $false))
    }
    Write-Host ("Version injected: {0}" -f $tf.FullName.Substring($stage.Length + 1)) -ForegroundColor DarkGray
  }
  if (-not $tokenFiles) { Write-Warning 'No %%EBOS_VERSION%% tokens found - version strings may be hardcoded.' }

  # Fail closed: no raw token may survive into the package (builder itself excluded, see above).
  $leftover = Get-ChildItem -Path $stage -Recurse -File -ErrorAction SilentlyContinue |
    Where-Object { $_.Name -notin @('Build-Playbook.ps1', 'build-playbook.cmd') } |
    Where-Object { (Get-Content -LiteralPath $_.FullName -Raw -Encoding UTF8 -ErrorAction SilentlyContinue) -match '%%EBOS_VERSION%%' }
  if ($leftover) { throw ("Unreplaced version token in: " + (($leftover | Select-Object -ExpandProperty FullName) -join ', ')) }

  Write-Host "Compressing to $outFile ..." -ForegroundColor Cyan
  # Compress-Archive (5.1) only supports '.zip' - build to temp zip then rename to .apbx.
  $tmpZip = "$outFile.tmp.zip"
  if (Test-Path $tmpZip) { Remove-Item -LiteralPath $tmpZip -Force }
  Compress-Archive -Path (Join-Path $stage '*') -DestinationPath $tmpZip -CompressionLevel Optimal -Force
  Move-Item -LiteralPath $tmpZip -Destination $outFile -Force

  $size = (Get-Item $outFile).Length
  Write-Host ("Built {0} ({1:N1} MB)" -f $outFile, ($size / 1MB)) -ForegroundColor Green

  # 4. Quick sanity: list top-level entries.
  Write-Host 'Top-level entries:' -ForegroundColor Cyan
  # Use tar (bsdtar, ships with Windows) to list zip contents without expanding.
  try {
    tar -tf $outFile | ForEach-Object { ($_ -split '/')[0] } | Sort-Object -Unique | Write-Output
  } catch {
    Write-Warning "Could not list archive contents: $_"
  }
} finally {
  Remove-Item -LiteralPath $stage -Recurse -Force -ErrorAction SilentlyContinue
}
