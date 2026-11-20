<#
.SYNOPSIS
    Bumps the Atlas package version in playbook.conf and Atlas Manager.
.DESCRIPTION
    In playbook.conf, sets <Version> and adds the previous version to <UpgradableFrom>,
    keeping the sources already listed. Sets the same version in app/Cargo.toml and in
    the atlas-app entry of app/Cargo.lock, which the --locked app builds need.

    When playbook.conf already has the version, it's left as it is and only the other
    files that disagree with it are brought in line.
.PARAMETER Version
    The new version, as major.minor.patch.
.PARAMETER PlaybookConfPath
    The playbook.conf to bump. The default is the repository's.
.PARAMETER CargoTomlPath
    Atlas Manager's Cargo.toml. The default is app/Cargo.toml in the same repository.
.PARAMETER CargoLockPath
    Atlas Manager's Cargo.lock. The default is app/Cargo.lock in the same repository.
.EXAMPLE
    tools/build/Set-AtlasVersion.ps1 -Version 0.6.0
#>
#requires -Version 7.0
[CmdletBinding(SupportsShouldProcess = $true)]
Param(
    # All three numbers: Cargo needs them, and the release tag must equal this version.
    [Parameter(Mandatory = $true)]
    [ValidatePattern('^(0|[1-9]\d*)(\.(0|[1-9]\d*)){2}$')]
    [string]$Version,

    [string]$PlaybookConfPath,

    [string]$CargoTomlPath,

    [string]$CargoLockPath
)

Set-StrictMode -Version 3.0
$ErrorActionPreference = 'Stop'

if (-not $PlaybookConfPath) {
    $PlaybookConfPath = Join-Path -Path $PSScriptRoot -ChildPath '..\..\playbook\playbook.conf'
}
$PlaybookConfPath = (Resolve-Path -LiteralPath $PlaybookConfPath).ProviderPath

$repositoryRoot = Split-Path -Path (Split-Path -Path $PlaybookConfPath -Parent) -Parent
if (-not $CargoTomlPath) {
    $CargoTomlPath = Join-Path -Path $repositoryRoot -ChildPath 'app\Cargo.toml'
}
$CargoTomlPath = (Resolve-Path -LiteralPath $CargoTomlPath).ProviderPath
if (-not $CargoLockPath) {
    $CargoLockPath = Join-Path -Path $repositoryRoot -ChildPath 'app\Cargo.lock'
}
$CargoLockPath = (Resolve-Path -LiteralPath $CargoLockPath).ProviderPath

$lines = Get-Content -LiteralPath $PlaybookConfPath -Encoding UTF8

$currentVersion = $null
foreach ($line in $lines) {
    if ($line -match '<Version>\s*(?<v>[^<]+?)\s*</Version>') {
        $currentVersion = $Matches['v']
        break
    }
}

if (-not $currentVersion) {
    throw "Could not find a <Version> element in '$PlaybookConfPath'."
}

# A conf already at the version stays as it is: rewriting a single UpgradableFrom
# source would replace it with the version itself.
$bumpConf = $currentVersion -ne $Version
if ($bumpConf) {
    $updated = foreach ($line in $lines) {
        if ($line -match '<Version>\s*[^<]+?\s*</Version>') {
            $line -replace '(<Version>\s*)[^<]+?(\s*</Version>)', "`${1}$Version`${2}"
        }
        elseif ($line -match '<UpgradableFrom>\s*[^<]+?\s*</UpgradableFrom>') {
            $line -replace '(<UpgradableFrom>\s*)[^<]+?(\s*</UpgradableFrom>)', "`${1}$currentVersion`${2}"
        }
        else {
            $line
        }
    }

    # <UpgradableFrom> holds either one version as its text or a list of <string>
    # sources. A list keeps its sources when the superseded release is added.
    $updatedText = $updated -join [Environment]::NewLine
    $arrayPattern = '(?s)(<UpgradableFrom>)(?=\s*<string>)(.*?)(\s*</UpgradableFrom>)'
    $arrayMatch = [regex]::Match($updatedText, $arrayPattern)
    if ($arrayMatch.Success) {
        $sourceVersions = @([regex]::Matches($arrayMatch.Groups[2].Value, '<string>\s*([^<]+?)\s*</string>') | ForEach-Object { $_.Groups[1].Value })
        if ($sourceVersions -cnotcontains $currentVersion) {
            $indentMatch = [regex]::Match($arrayMatch.Groups[2].Value, '(?:\r?\n)([ \t]*)<string>')
            $indent = if ($indentMatch.Success) { $indentMatch.Groups[1].Value } else { "`t`t`t" }
            $replacement = $arrayMatch.Groups[1].Value + $arrayMatch.Groups[2].Value.TrimEnd() +
                [Environment]::NewLine + $indent + '<string>' + $currentVersion + '</string>' + $arrayMatch.Groups[3].Value
            $updatedText = $updatedText.Remove($arrayMatch.Index, $arrayMatch.Length).Insert($arrayMatch.Index, $replacement)
        }
    }
    $updated = $updatedText -split '\r?\n'
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
if (-not $bumpConf) {
    if ($pending.Count -eq 0) {
        Write-Warning "playbook.conf is already at version $Version, and so is every other file; nothing to do."
        return
    }
    Write-Warning "playbook.conf is already at version $Version; bringing $($pending -join ', ') in line with it."
}

if ($bumpConf -and $PSCmdlet.ShouldProcess($PlaybookConfPath, "Set version to $Version (was $currentVersion)")) {
    Set-Content -LiteralPath $PlaybookConfPath -Value $updated -Encoding UTF8
    Write-Host "playbook.conf version: $currentVersion -> $Version (previous version added to upgrade sources)." -ForegroundColor Green
}

if ($pending -contains 'Cargo.toml' -and $PSCmdlet.ShouldProcess($CargoTomlPath, "Set the package version to $Version")) {
    [IO.File]::WriteAllText($CargoTomlPath, $updatedCargoToml, [Text.UTF8Encoding]::new($false))
    Write-Host "Cargo.toml: package version set to $Version." -ForegroundColor Green
}

if ($pending -contains 'Cargo.lock' -and $PSCmdlet.ShouldProcess($CargoLockPath, "Set the atlas-app version to $Version")) {
    [IO.File]::WriteAllText($CargoLockPath, $updatedCargoLock, [Text.UTF8Encoding]::new($false))
    Write-Host "Cargo.lock: atlas-app version set to $Version." -ForegroundColor Green
}
