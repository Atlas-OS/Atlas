$ErrorActionPreference = 'Stop'

$razerPath = Join-Path -Path ([Environment]::GetFolderPath('Windows')) -ChildPath 'Installer\Razer'
New-Item -Path $razerPath -ItemType Directory -Force | Out-Null

$resolvedRazerPath = (Resolve-Path -LiteralPath $razerPath).ProviderPath
$windowsInstallerRoot = Join-Path -Path ([Environment]::GetFolderPath('Windows')) -ChildPath 'Installer'
$resolvedInstallerRoot = (Resolve-Path -LiteralPath $windowsInstallerRoot).ProviderPath.TrimEnd('\')

if (-not $resolvedRazerPath.StartsWith($resolvedInstallerRoot + '\', [StringComparison]::OrdinalIgnoreCase)) {
    throw "Refusing to clear unexpected Razer installer path '$resolvedRazerPath'."
}

Get-ChildItem -LiteralPath $resolvedRazerPath -Force -ErrorAction Stop |
    Remove-Item -Recurse -Force -ErrorAction Stop

$denyRule = '*S-1-1-0:(W)'
$icaclsPath = Join-Path -Path ([Environment]::SystemDirectory) -ChildPath 'icacls.exe'
Invoke-AtlasHiddenProcess -FilePath $icaclsPath `
    -ArgumentList @($resolvedRazerPath, '/deny', $denyRule) -Wait | Out-Null
