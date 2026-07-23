<#
.SYNOPSIS
    Bumps the Atlas playbook version in playbook.conf: sets <Version>, rewrites <Title>
    to "Atlas v<Version>" (preserving a "(dev)" suffix), and moves the previous version
    into <UpgradableFrom>. Also rewrites every onUpgradeVersions entry in
    Configuration/custom.yml to the new version so the upgrade-only actions stay bound
    to the shipped version. playbook.conf is the single source of truth for the version.
.EXAMPLE
    tools/build/Set-AtlasVersion.ps1 -Version 0.6.0
#>
#requires -Version 7.0
[CmdletBinding(SupportsShouldProcess = $true)]
Param(
    [Parameter(Mandatory = $true)]
    [ValidatePattern('^(0|[1-9]\d*)(\.(0|[1-9]\d*)){0,2}$')]
    [string]$Version,

    [string]$PlaybookConfPath,

    [string]$CustomYmlPath
)

Set-StrictMode -Version 3.0
$ErrorActionPreference = 'Stop'

if (-not $PlaybookConfPath) {
    $PlaybookConfPath = Join-Path -Path $PSScriptRoot -ChildPath '..\..\playbook\playbook.conf'
}
$PlaybookConfPath = (Resolve-Path -LiteralPath $PlaybookConfPath).ProviderPath

if (-not $CustomYmlPath) {
    $CustomYmlPath = Join-Path -Path (Split-Path -Path $PlaybookConfPath -Parent) `
        -ChildPath 'Configuration\custom.yml'
}
$CustomYmlPath = (Resolve-Path -LiteralPath $CustomYmlPath).ProviderPath

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

if ($currentVersion -eq $Version) {
    Write-Warning "playbook.conf is already at version $Version; nothing to do."
    return
}

$updated = foreach ($line in $lines) {
    if ($line -match '<Version>\s*[^<]+?\s*</Version>') {
        $line -replace '(<Version>\s*)[^<]+?(\s*</Version>)', "`${1}$Version`${2}"
    }
    elseif ($line -match '<UpgradableFrom>\s*[^<]+?\s*</UpgradableFrom>') {
        $line -replace '(<UpgradableFrom>\s*)[^<]+?(\s*</UpgradableFrom>)', "`${1}$currentVersion`${2}"
    }
    elseif ($line -match '<Title>\s*[^<]*?\s*</Title>') {
        # Keep everything before "v<number>" (e.g. "Atlas ") and any trailing " (dev)".
        $suffix = ''
        if ($line -match '\(dev\)') { $suffix = ' (dev)' }
        $line -replace '(<Title>\s*).*?(\s*</Title>)', "`${1}Atlas v$Version$suffix`${2}"
    }
    else {
        $line
    }
}

$customYmlText = [IO.File]::ReadAllText($CustomYmlPath)
$onUpgradePattern = '(onUpgradeVersions:\s*\[)[^\]]*(\])'
$onUpgradeMatches = [regex]::Matches($customYmlText, $onUpgradePattern)
if ($onUpgradeMatches.Count -eq 0) {
    throw "Could not find any onUpgradeVersions entries in '$CustomYmlPath'."
}
$updatedCustomYml = [regex]::Replace($customYmlText, $onUpgradePattern, "`${1}'$Version'`${2}")

if ($PSCmdlet.ShouldProcess($PlaybookConfPath, "Set version to $Version (was $currentVersion)")) {
    Set-Content -LiteralPath $PlaybookConfPath -Value $updated -Encoding UTF8
    Write-Host "playbook.conf version: $currentVersion -> $Version (UpgradableFrom set to $currentVersion)." -ForegroundColor Green
}

if ($PSCmdlet.ShouldProcess($CustomYmlPath, "Set every onUpgradeVersions entry to $Version")) {
    [IO.File]::WriteAllText($CustomYmlPath, $updatedCustomYml, [Text.UTF8Encoding]::new($false))
    Write-Host "custom.yml: $($onUpgradeMatches.Count) onUpgradeVersions entries set to $Version." -ForegroundColor Green
}
