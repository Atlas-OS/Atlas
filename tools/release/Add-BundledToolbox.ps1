#requires -Version 7.0
<#
.SYNOPSIS
    Adds a Toolbox installer to a staged copy of the Atlas package source for a release
    candidate. Atlas then installs that Toolbox instead of the latest release on GitHub,
    so testers get the Toolbox the candidate needs before it is published. Releases
    carry none.
.PARAMETER PackagePath
    The staged copy of package/ to add the installer to. The checkout's own package/ is
    refused.
.PARAMETER Installer
    The Toolbox installer to bundle.
.PARAMETER Version
    The version the installer records, which Atlas checks after installing it.
.EXAMPLE
    pwsh tools/release/Add-BundledToolbox.ps1 -PackagePath $staged -Installer AtlasToolbox-Setup.exe -Version 0.2.0
.NOTES
    Exit codes: 0 when the installer is bundled, 1 otherwise.
#>
param(
    [Parameter(Mandatory = $true)][string]$PackagePath,
    [Parameter(Mandatory = $true)][string]$Installer,
    [Parameter(Mandatory = $true)][ValidatePattern('^[0-9]+\.[0-9]+\.[0-9]+$')][string]$Version
)

Set-StrictMode -Version 3.0
$ErrorActionPreference = 'Stop'

$package = (Resolve-Path -LiteralPath $PackagePath).ProviderPath
if (-not (Test-Path -LiteralPath (Join-Path $package 'atlas.json') -PathType Leaf)) {
    throw "atlas.json not found in '$package'; it isn't an Atlas package source folder."
}
$checkout = [IO.Path]::GetFullPath((Join-Path $PSScriptRoot '../../package'))
if ([string]::Equals([IO.Path]::TrimEndingDirectorySeparator($package),
        [IO.Path]::TrimEndingDirectorySeparator($checkout), [StringComparison]::OrdinalIgnoreCase)) {
    throw "Bundle the Toolbox into a staged copy of package/, not the checkout's own folder."
}
$source = Get-Item -LiteralPath $Installer
if ($source.PSIsContainer -or $source.Length -le 0) {
    throw "The Toolbox installer '$Installer' is not a non-empty file."
}

$destination = Join-Path $package 'Executables/AtlasModules/Bundled/Toolbox'
New-Item -ItemType Directory -Force -Path $destination | Out-Null
$bundled = Join-Path $destination 'AtlasToolbox-Setup.exe'
Copy-Item -LiteralPath $source.FullName -Destination $bundled -Force
$manifest = [ordered]@{
    version = $Version
    sha256  = (Get-FileHash -LiteralPath $bundled -Algorithm SHA256).Hash
    size    = (Get-Item -LiteralPath $bundled).Length
}
[IO.File]::WriteAllText((Join-Path $destination 'AtlasToolbox-Setup.json'),
    ($manifest | ConvertTo-Json) + "`n", [Text.UTF8Encoding]::new($false))
Write-Host "Bundled Atlas Toolbox $Version ($($manifest.size) bytes, SHA-256 $($manifest.sha256))."
