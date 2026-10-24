#requires -Version 7.0
<#
.SYNOPSIS
    Adds a Toolbox installer to a staged copy of the Atlas package source for a release
    candidate. Atlas then installs that Toolbox instead of the latest release on GitHub,
    so testers get the Toolbox the candidate needs before it is published. Releases
    carry none.
.EXAMPLE
    pwsh tools/release/Add-BundledToolbox.ps1 -PlaybookPath $staged -Installer AtlasToolbox-Setup.exe -Version 0.2.0
#>
param(
    [Parameter(Mandatory = $true)][string]$PlaybookPath,
    [Parameter(Mandatory = $true)][string]$Installer,
    # The version the installer records, which Atlas checks after installing it.
    [Parameter(Mandatory = $true)][ValidatePattern('^[0-9]+\.[0-9]+\.[0-9]+$')][string]$Version
)

Set-StrictMode -Version 3.0
$ErrorActionPreference = 'Stop'

$playbook = (Resolve-Path -LiteralPath $PlaybookPath).ProviderPath
if (-not (Test-Path -LiteralPath (Join-Path $playbook 'playbook.conf') -PathType Leaf)) {
    throw "playbook.conf not found in '$playbook' - not an Atlas package source folder."
}
$checkout = [IO.Path]::GetFullPath((Join-Path $PSScriptRoot '../../playbook'))
if ([string]::Equals([IO.Path]::TrimEndingDirectorySeparator($playbook),
        [IO.Path]::TrimEndingDirectorySeparator($checkout), [StringComparison]::OrdinalIgnoreCase)) {
    throw "Bundle the Toolbox into a staged copy of playbook/, not the checkout's own folder."
}
$source = Get-Item -LiteralPath $Installer
if ($source.PSIsContainer -or $source.Length -le 0) {
    throw "The Toolbox installer '$Installer' is not a non-empty file."
}

$destination = Join-Path $playbook 'Executables/AtlasModules/Bundled/Toolbox'
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
