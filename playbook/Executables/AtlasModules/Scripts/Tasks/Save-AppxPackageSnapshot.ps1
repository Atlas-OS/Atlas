$ErrorActionPreference = 'Stop'

$atlasModulesPath = Join-Path -Path ([Environment]::GetFolderPath('Windows')) -ChildPath 'AtlasModules'
$snapshotPath = Join-Path -Path $atlasModulesPath -ChildPath 'AtlasPackagesOld.txt'

if (-not (Test-Path -LiteralPath $atlasModulesPath -PathType Container)) {
    New-Item -Path $atlasModulesPath -ItemType Directory -Force | Out-Null
}

(Get-AppxPackage).PackageFamilyName | Set-Content -LiteralPath $snapshotPath -Encoding ASCII
