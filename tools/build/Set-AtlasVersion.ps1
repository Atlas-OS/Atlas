<#
.SYNOPSIS
    Bumps the Atlas package version in atlas.json and Atlas Manager.
.DESCRIPTION
    In atlas.json, sets version and adds the previous version to updatableFrom, keeping
    the versions already listed. Sets the same version in app/Cargo.toml and in the
    atlas-app entry of app/Cargo.lock, which the --locked app builds need.

    When atlas.json already has the version, it's left as it is and only the other
    files that disagree with it are brought in line.
.PARAMETER Version
    The new version, as major.minor.patch.
.PARAMETER ManifestPath
    The atlas.json to bump. The default is the repository's package/atlas.json.
.PARAMETER CargoTomlPath
    Atlas Manager's Cargo.toml. The default is app/Cargo.toml in the same repository.
.PARAMETER CargoLockPath
    Atlas Manager's Cargo.lock. The default is app/Cargo.lock in the same repository.
.EXAMPLE
    tools/build/Set-AtlasVersion.ps1 -Version 0.6.0
.NOTES
    Exit codes: 0 when every file has the version, 1 when a file can't be read or bumped.
#>
#requires -Version 7.0
[CmdletBinding(SupportsShouldProcess = $true)]
Param(
    # All three numbers: Cargo needs them, and the release tag must equal this version.
    [Parameter(Mandatory = $true)]
    [ValidatePattern('^(0|[1-9]\d*)(\.(0|[1-9]\d*)){2}$')]
    [string]$Version,

    [string]$ManifestPath,

    [string]$CargoTomlPath,

    [string]$CargoLockPath
)

Set-StrictMode -Version 3.0
$ErrorActionPreference = 'Stop'

Import-Module (Join-Path -Path $PSScriptRoot -ChildPath 'AtlasBuild\AtlasBuild.psd1') -Force

if (-not $ManifestPath) {
    $ManifestPath = Join-Path -Path $PSScriptRoot -ChildPath '..\..\package\atlas.json'
}
$ManifestPath = (Resolve-Path -LiteralPath $ManifestPath).ProviderPath

$repositoryRoot = Split-Path -Path (Split-Path -Path $ManifestPath -Parent) -Parent
if (-not $CargoTomlPath) {
    $CargoTomlPath = Join-Path -Path $repositoryRoot -ChildPath 'app\Cargo.toml'
}
$CargoTomlPath = (Resolve-Path -LiteralPath $CargoTomlPath).ProviderPath
if (-not $CargoLockPath) {
    $CargoLockPath = Join-Path -Path $repositoryRoot -ChildPath 'app\Cargo.lock'
}
$CargoLockPath = (Resolve-Path -LiteralPath $CargoLockPath).ProviderPath

$currentVersion = (Get-AtlasPackageVersion -ManifestPath $ManifestPath).Version

# A manifest already at the version stays byte for byte as it is.
$bumpManifest = $currentVersion -cne $Version
if ($bumpManifest) {
    $manifest = [System.Text.Json.Nodes.JsonNode]::Parse([IO.File]::ReadAllText($ManifestPath))
    $sources = $manifest['updatableFrom']
    if ($sources -isnot [System.Text.Json.Nodes.JsonArray]) {
        throw "updatableFrom in '$ManifestPath' isn't an array of versions."
    }
    $listed = @(foreach ($source in $sources) { "$source" })
    if ($listed -cnotcontains $currentVersion) {
        $sources.Add([System.Text.Json.Nodes.JsonValue]::Create($currentVersion))
    }
    $manifest['version'] = [System.Text.Json.Nodes.JsonValue]::Create($Version)
    $updatedManifest = ConvertTo-AtlasManifestJson -Manifest $manifest
}

# The first line that starts with a version key is the [package] one: dependencies
# only use inline version keys.
$cargoTomlText = [IO.File]::ReadAllText($CargoTomlPath)
$cargoTomlPattern = [regex]::new('(?m)^(version\s*=\s*")[^"]*(")')
if (-not $cargoTomlPattern.IsMatch($cargoTomlText)) {
    throw "Could not find the package version in '$CargoTomlPath'."
}
$updatedCargoToml = $cargoTomlPattern.Replace($cargoTomlText, "`${1}$Version`${2}", 1)

$cargoLockText = [IO.File]::ReadAllText($CargoLockPath)
$cargoLockPattern = '(?m)^(name = "atlas-app"\r?\nversion = ")[^"]*(")'
if (-not [regex]::IsMatch($cargoLockText, $cargoLockPattern)) {
    throw "Could not find the atlas-app entry in '$CargoLockPath'."
}
$updatedCargoLock = [regex]::Replace($cargoLockText, $cargoLockPattern, "`${1}$Version`${2}")

$pending = @(
    if ($updatedCargoToml -cne $cargoTomlText) { 'Cargo.toml' }
    if ($updatedCargoLock -cne $cargoLockText) { 'Cargo.lock' }
)
if (-not $bumpManifest) {
    if ($pending.Count -eq 0) {
        Write-Warning "atlas.json is already at version $Version, and so is every other file; nothing to do."
        return
    }
    Write-Warning "atlas.json is already at version $Version; bringing $($pending -join ', ') in line with it."
}

$utf8NoBom = [Text.UTF8Encoding]::new($false)
if ($bumpManifest -and $PSCmdlet.ShouldProcess($ManifestPath, "Set version to $Version (was $currentVersion)")) {
    [IO.File]::WriteAllText($ManifestPath, $updatedManifest, $utf8NoBom)
    Write-Host "atlas.json version: $currentVersion -> $Version (previous version added to updatableFrom)." -ForegroundColor Green
}

if ($pending -contains 'Cargo.toml' -and $PSCmdlet.ShouldProcess($CargoTomlPath, "Set the package version to $Version")) {
    [IO.File]::WriteAllText($CargoTomlPath, $updatedCargoToml, $utf8NoBom)
    Write-Host "Cargo.toml: package version set to $Version." -ForegroundColor Green
}

if ($pending -contains 'Cargo.lock' -and $PSCmdlet.ShouldProcess($CargoLockPath, "Set the atlas-app version to $Version")) {
    [IO.File]::WriteAllText($CargoLockPath, $updatedCargoLock, $utf8NoBom)
    Write-Host "Cargo.lock: atlas-app version set to $Version." -ForegroundColor Green
}
