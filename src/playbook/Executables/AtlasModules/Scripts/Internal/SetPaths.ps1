$ErrorActionPreference = 'Stop'

$isAdmin = ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
if (-not $isAdmin) {
    Start-Process -FilePath 'powershell.exe' -Verb RunAs -ArgumentList @('-NoProfile', '-ExecutionPolicy', 'Bypass', '-File', $PSCommandPath)
    exit
}

$windir = [Environment]::GetFolderPath('Windows')
$atlasDesktop = Join-Path -Path $windir -ChildPath 'AtlasDesktop'
$rootPath = 'HKLM:\SOFTWARE\AtlasOS\Services'

if (-not (Test-Path -LiteralPath $rootPath)) {
    Write-Output "Atlas service registry root '$rootPath' was not found; no paths need updating."
    return
}

$registryKeys = Get-ChildItem -LiteralPath $rootPath -Recurse -ErrorAction Stop | Where-Object { $_.PSIsContainer }
$marker = 'AtlasDesktop\'

foreach ($key in $registryKeys) {
    $property = Get-ItemProperty -LiteralPath $key.PSPath -Name 'path' -ErrorAction SilentlyContinue
    if (-not $property -or [string]::IsNullOrWhiteSpace($property.path)) {
        continue
    }

    $path = [string]$property.path
    Write-Output $path

    if ($path -like "$atlasDesktop\*") {
        continue
    }

    $index = $path.IndexOf($marker, [System.StringComparison]::OrdinalIgnoreCase)
    if ($index -lt 0) {
        Write-Warning "Skipping Atlas service path without '$marker': $path"
        continue
    }

    $relativePath = $path.Substring($index + $marker.Length)
    Set-ItemProperty -LiteralPath $key.PSPath -Name 'path' -Value (Join-Path -Path $atlasDesktop -ChildPath $relativePath) -ErrorAction Stop
}
