$ErrorActionPreference = 'Stop'

$snapshotPath = Join-Path -Path ([Environment]::GetFolderPath('Windows')) -ChildPath 'AtlasModules\AtlasPackagesOld.txt'
if (-not (Test-Path -LiteralPath $snapshotPath -PathType Leaf)) {
    throw "AppX package snapshot '$snapshotPath' was not found. Save-AppxPackageSnapshot.ps1 must run before deprovisioning."
}

$deprovisionedPath = 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Appx\AppxAllUserStore\Deprovisioned'
New-Item -Path $deprovisionedPath -Force | Out-Null

$oldPackages = Get-Content -LiteralPath $snapshotPath -ErrorAction Stop
$currentPackages = (Get-AppxPackage).PackageFamilyName
Compare-Object -ReferenceObject $oldPackages -DifferenceObject $currentPackages |
    Where-Object { $_.SideIndicator -eq '<=' } |
    Select-Object -ExpandProperty InputObject |
    ForEach-Object {
        New-Item -Path $deprovisionedPath -Name $_ -Force | Out-Null
    }

Remove-Item -LiteralPath $snapshotPath -Force -ErrorAction Stop
