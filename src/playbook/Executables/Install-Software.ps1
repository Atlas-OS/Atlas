[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)][string]$Id,
    [string]$Version
)

$ErrorActionPreference = 'Stop'

function Test-WingetUsable {
    $cmd = Get-Command winget.exe -ErrorAction SilentlyContinue
    if (-not $cmd) { return $null }
    try {
        # A bare App-Execution-Alias stub (no App Installer) either fails or
        # prints no version - require a real 'x.y' version string.
        $out = & $cmd.Source --version 2>$null
        if ($LASTEXITCODE -eq 0 -and "$out" -match '\d+\.\d+') { return $cmd.Source }
    } catch { }
    return $null
}

function Install-WingetBootstrap {
    # Best-effort App Installer bootstrap for bare images (winget missing or stub).
    Write-Output 'winget not usable; attempting App Installer bootstrap...'
    $work = Join-Path $env:TEMP ('winget-bootstrap-' + [guid]::NewGuid().ToString('N'))
    New-Item -ItemType Directory -Force -Path $work | Out-Null
    try {
        # Dependencies first (ignored if already present / download fails).
        $deps = @(
            'https://aka.ms/Microsoft.VCLibs.x64.14.00.Desktop.appx',
            'https://aka.ms/Microsoft.UI.Xaml.2.8.x64.appx'
        )
        foreach ($dep in $deps) {
            try {
                $dst = Join-Path $work ([IO.Path]::GetFileName(($dep -split '\?')[0]))
                Invoke-WebRequest -Uri $dep -OutFile $dst -UseBasicParsing -TimeoutSec 120
                Add-AppxPackage -Path $dst -ErrorAction Stop
                Write-Output ("Installed dependency: " + [IO.Path]::GetFileName($dst))
            } catch {
                Write-Warning ("Dependency skipped/failed ($dep): $_")
            }
        }
        $bundle = Join-Path $work 'Microsoft.DesktopAppInstaller.msixbundle'
        Invoke-WebRequest -Uri 'https://aka.ms/getwinget' -OutFile $bundle -UseBasicParsing -TimeoutSec 300
        Add-AppxPackage -Path $bundle -ErrorAction Stop
        Write-Output 'App Installer bootstrap installed.'
    } finally {
        Remove-Item $work -Recurse -Force -ErrorAction SilentlyContinue
    }
}

$wingetExe = Test-WingetUsable
if (-not $wingetExe) {
    try {
        Install-WingetBootstrap
    } catch {
        Write-Warning "App Installer bootstrap failed: $_"
    }
    $wingetExe = Test-WingetUsable
}
if (-not $wingetExe) {
    Write-Warning "winget not found; cannot install $Id. Install 'App Installer' from the Microsoft Store and re-run."
    exit 1
}

$baseArgs = @('install', '--id', $Id, '--exact', '--silent',
          '--accept-package-agreements', '--accept-source-agreements', '--source', 'winget')
if ($Version) { $baseArgs += '--version', $Version }

$attempt = 0
$maxAttempts = 3
$code = 1
while ($attempt -lt $maxAttempts) {
    $attempt++
    Write-Output "Installing $Id via winget (attempt $attempt/$maxAttempts)..."
    $proc = Start-Process -FilePath $wingetExe -ArgumentList $baseArgs -Wait -PassThru -NoNewWindow
    $code = $proc.ExitCode
    if ($code -eq 0) { break }
    # winget can return non-zero even when the package ends up installed
    # (e.g. "already installed" / "no applicable upgrade"). Treat that as success.
    $listed = & $wingetExe list --id $Id --exact --source winget 2>$null
    if ($listed -match [regex]::Escape($Id)) {
        Write-Output "$Id is already installed; treating as success."
        exit 0
    }
    if ($attempt -lt $maxAttempts) {
        Write-Warning "winget exited with code $code; retrying in 10s..."
        Start-Sleep -Seconds 10
    }
}

if ($code -ne 0) {
    Write-Warning "winget exited with code $code while installing $Id."
    exit $code
}

Write-Output "$Id installed successfully."
exit 0
