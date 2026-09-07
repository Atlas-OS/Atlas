[CmdletBinding(DefaultParameterSetName = 'File')]
param(
    [Parameter(Mandatory, ParameterSetName = 'File')][string]$MarkdownPath,
    [Parameter(Mandatory, ParameterSetName = 'Refresh')][switch]$Refresh,
    [datetime]$AsOfDate = [datetime]::UtcNow.Date,
    [string]$OutputPath = (Join-Path $PSScriptRoot '../../playbook/Executables/AtlasModules/Scripts/Compatibility/windows-releases.json')
)
$ErrorActionPreference = 'Stop'
. (Join-Path $PSScriptRoot '../../playbook/Executables/AtlasModules/Scripts/Compatibility/Windows-Release.ps1')
$markdown = if ($Refresh) { Get-AtlasWindowsReleaseMarkdown } else { [IO.File]::ReadAllText((Resolve-Path -LiteralPath $MarkdownPath).Path) }
$releases = @(ConvertFrom-AtlasWindowsReleaseMarkdown -Markdown $markdown -AsOfDate $AsOfDate)
$commit = [regex]::Match($markdown, '(?m)^git_commit_id: ([0-9a-f]{40})\s*$').Groups[1].Value
$updated = [regex]::Match($markdown, '(?m)^updated_at: ([^\r\n]+)').Groups[1].Value.Trim()
if (-not $commit -or -not $updated) { throw 'Official source metadata is missing; review the source format.' }
$sha = [Security.Cryptography.SHA256]::Create()
try { $hash = ([BitConverter]::ToString($sha.ComputeHash([Text.Encoding]::UTF8.GetBytes($markdown)))).Replace('-', '') }
finally { $sha.Dispose() }
$catalog = [ordered]@{
    schemaVersion = 1
    product = 'Windows 11'
    release = '25H2'
    build = 26200
    sourceUrl = 'https://learn.microsoft.com/en-us/windows/release-health/windows11-release-information'
    sourceCommit = $commit
    sourceSha256 = $hash
    updatedAt = $updated
    asOfDate = $AsOfDate.ToString('yyyy-MM-dd', [Globalization.CultureInfo]::InvariantCulture)
    releases = $releases
}
$text = ($catalog | ConvertTo-Json -Depth 5).Replace("`r`n", "`n") + "`n"
[IO.File]::WriteAllText([IO.Path]::GetFullPath($OutputPath), $text, [Text.UTF8Encoding]::new($false))
Write-Output "Wrote $($releases.Count) published 25H2 versions. Review the catalog diff before publishing."
