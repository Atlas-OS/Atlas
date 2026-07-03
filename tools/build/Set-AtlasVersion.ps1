<#
.SYNOPSIS
    Bumps the Atlas playbook version in playbook.conf: sets <Version>, rewrites <Title>
    to "Atlas v<Version>" (preserving a "(dev)" suffix), and moves the previous version
    into <UpgradableFrom>. playbook.conf is the single source of truth for the version.
.EXAMPLE
    tools/build/Set-AtlasVersion.ps1 -Version 0.6.0
#>
[CmdletBinding(SupportsShouldProcess = $true)]
Param(
    [Parameter(Mandatory = $true)]
    [ValidatePattern('^(0|[1-9]\d*)(\.(0|[1-9]\d*)){0,2}$')]
    [string]$Version,

    [string]$PlaybookConfPath
)

Set-StrictMode -Version 3.0
$ErrorActionPreference = 'Stop'

if (-not $PlaybookConfPath) {
    $PlaybookConfPath = Join-Path -Path $PSScriptRoot -ChildPath '..\..\playbook\playbook.conf'
}
$PlaybookConfPath = (Resolve-Path -LiteralPath $PlaybookConfPath).ProviderPath

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

if ($PSCmdlet.ShouldProcess($PlaybookConfPath, "Set version to $Version (was $currentVersion)")) {
    Set-Content -LiteralPath $PlaybookConfPath -Value $updated -Encoding UTF8
    Write-Host "playbook.conf version: $currentVersion -> $Version (UpgradableFrom set to $currentVersion)." -ForegroundColor Green
}
