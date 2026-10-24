<#
.SYNOPSIS
    Bumps the Atlas package version in playbook.conf: sets <Version>, rewrites <Title>
    to "Atlas v<Version>" (preserving a "(dev)" suffix), and moves the previous version
    into <UpgradableFrom>, retaining an explicit list of supported sources. Also rewrites
    every onUpgradeVersions entry in Configuration/custom.yml to the new version so the
    upgrade-only actions stay bound to the released version, sets the same version in
    app/Cargo.toml and the atlas-app entry in app/Cargo.lock, which the --locked app
    builds need, and in the "Atlas v<Version> for Windows 11" options of the bug report
    template.
.DESCRIPTION
    When playbook.conf already has the version, it's left as it is and only the other
    files that disagree with it are brought in line.
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

    [string]$CustomYmlPath,

    [string]$CargoTomlPath,

    [string]$CargoLockPath,

    [string]$BugReportTemplatePath
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

$repositoryRoot = Split-Path -Path (Split-Path -Path $PlaybookConfPath -Parent) -Parent
if (-not $CargoTomlPath) {
    $CargoTomlPath = Join-Path -Path $repositoryRoot -ChildPath 'app\Cargo.toml'
}
$CargoTomlPath = (Resolve-Path -LiteralPath $CargoTomlPath).ProviderPath
if (-not $CargoLockPath) {
    $CargoLockPath = Join-Path -Path $repositoryRoot -ChildPath 'app\Cargo.lock'
}
$CargoLockPath = (Resolve-Path -LiteralPath $CargoLockPath).ProviderPath
if (-not $BugReportTemplatePath) {
    $BugReportTemplatePath = Join-Path -Path $repositoryRoot -ChildPath '.github\ISSUE_TEMPLATE\bug_report.yml'
}
$BugReportTemplatePath = (Resolve-Path -LiteralPath $BugReportTemplatePath).ProviderPath

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

    # AME accepts both one source version and a string list. Keep the reviewed
    # legacy sources when adding the release being superseded.
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

$customYmlText = [IO.File]::ReadAllText($CustomYmlPath)
$onUpgradePattern = '(onUpgradeVersions:\s*\[)[^\]]*(\])'
$onUpgradeMatches = [regex]::Matches($customYmlText, $onUpgradePattern)
if ($onUpgradeMatches.Count -eq 0) {
    throw "Could not find any onUpgradeVersions entries in '$CustomYmlPath'."
}
$updatedCustomYml = [regex]::Replace($customYmlText, $onUpgradePattern, "`${1}'$Version'`${2}")

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

$templateText = [IO.File]::ReadAllText($BugReportTemplatePath)
$templatePattern = '(?m)^([ \t]*- Atlas v)\d+\.\d+\.\d+( for Windows 11 )'
$templateMatches = [regex]::Matches($templateText, $templatePattern)
if ($templateMatches.Count -eq 0) {
    throw "Could not find any 'Atlas v<version> for Windows 11' options in '$BugReportTemplatePath'."
}
$updatedTemplate = [regex]::Replace($templateText, $templatePattern, "`${1}$Version`${2}")

$pending = @(
    if ($updatedCustomYml -cne $customYmlText) { 'custom.yml' }
    if ($updatedCargoToml -cne $cargoTomlText) { 'Cargo.toml' }
    if ($updatedCargoLock -cne $cargoLockText) { 'Cargo.lock' }
    if ($updatedTemplate -cne $templateText) { 'bug_report.yml' }
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

if ($pending -contains 'custom.yml' -and $PSCmdlet.ShouldProcess($CustomYmlPath, "Set every onUpgradeVersions entry to $Version")) {
    [IO.File]::WriteAllText($CustomYmlPath, $updatedCustomYml, [Text.UTF8Encoding]::new($false))
    Write-Host "custom.yml: $($onUpgradeMatches.Count) onUpgradeVersions entries set to $Version." -ForegroundColor Green
}

if ($pending -contains 'Cargo.toml' -and $PSCmdlet.ShouldProcess($CargoTomlPath, "Set the package version to $Version")) {
    [IO.File]::WriteAllText($CargoTomlPath, $updatedCargoToml, [Text.UTF8Encoding]::new($false))
    Write-Host "Cargo.toml: package version set to $Version." -ForegroundColor Green
}

if ($pending -contains 'Cargo.lock' -and $PSCmdlet.ShouldProcess($CargoLockPath, "Set the atlas-app version to $Version")) {
    [IO.File]::WriteAllText($CargoLockPath, $updatedCargoLock, [Text.UTF8Encoding]::new($false))
    Write-Host "Cargo.lock: atlas-app version set to $Version." -ForegroundColor Green
}

if ($pending -contains 'bug_report.yml' -and $PSCmdlet.ShouldProcess($BugReportTemplatePath, "Set every Atlas version option to $Version")) {
    [IO.File]::WriteAllText($BugReportTemplatePath, $updatedTemplate, [Text.UTF8Encoding]::new($false))
    Write-Host "bug_report.yml: $($templateMatches.Count) Atlas version options set to $Version." -ForegroundColor Green
}
