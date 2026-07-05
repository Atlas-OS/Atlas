$ErrorActionPreference = 'Stop'

Import-Module -Name (Join-Path $PSScriptRoot '..\Modules\Atlas.Core\Atlas.Core.psd1') -Force

if (-not (Test-AtlasAdmin)) {
    Start-Process -FilePath 'powershell.exe' -Verb RunAs -ArgumentList @('-NoProfile', '-ExecutionPolicy', 'Bypass', '-File', $PSCommandPath)
    exit
}

$windir = [Environment]::GetFolderPath('Windows')
$atlasDesktop = Join-Path -Path $windir -ChildPath 'AtlasDesktop'
$rootPath = 'HKLM:\SOFTWARE\AtlasOS\Services'

if (-not (Test-Path -LiteralPath $rootPath)) {
    Write-AtlasLog -Message "Atlas service registry root '$rootPath' was not found; no paths need updating."
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
    Write-AtlasLog -Message "Checking recorded launcher path: $path"

    if ($path -like "$atlasDesktop\*") {
        continue
    }

    $index = $path.IndexOf($marker, [System.StringComparison]::OrdinalIgnoreCase)
    if ($index -lt 0) {
        Write-AtlasLog -Level Warning -Message "Skipping Atlas service path without '$marker': $path"
        continue
    }

    $relativePath = $path.Substring($index + $marker.Length)
    Set-ItemProperty -LiteralPath $key.PSPath -Name 'path' -Value (Join-Path -Path $atlasDesktop -ChildPath $relativePath) -ErrorAction Stop
}
