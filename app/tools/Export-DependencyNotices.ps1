#Requires -Version 7.2
# Source inputs come from Cargo's locked Windows resolution;
# this command never downloads license text or silently invents missing notices.
[CmdletBinding()]
param(
    [switch]$Check,
    [string]$AppDirectory = (Split-Path -Parent $PSScriptRoot)
)

$ErrorActionPreference = 'Stop'
$app = [IO.Path]::GetFullPath($AppDirectory)
function Get-NoticeHash([string]$Text) {
    [Convert]::ToHexString([Security.Cryptography.SHA256]::HashData([Text.Encoding]::UTF8.GetBytes($Text.Replace("`r`n", "`n"))))
}
Push-Location $app
try {
    $metadataText = & cargo metadata --locked --format-version 1 --filter-platform x86_64-pc-windows-msvc
    if ($LASTEXITCODE) { throw 'Cargo metadata failed.' }
    $metadata = $metadataText | ConvertFrom-Json
    $normal = @(& cargo tree --locked --target x86_64-pc-windows-msvc --edges normal,no-proc-macro --prefix none --format '{p}' | ForEach-Object { $_ -replace ' \(\*\)$', '' })
    if ($LASTEXITCODE) { throw 'Cargo dependency tree failed.' }
    $supplements = Get-Content (Join-Path $app 'licenses/supplements.json') -Raw | ConvertFrom-Json
    $sections = [System.Collections.Generic.List[string]]::new()
    $inventory = [System.Collections.Generic.List[object]]::new()
    $unresolved = [System.Collections.Generic.List[string]]::new()
    $sections.Add("ATLAS THIRD-PARTY NOTICES`n`nThis conservative inventory includes the locked Windows dependency resolution, including build and development packages. Inclusion does not assert that a package is linked into AtlasManager.exe. Original license and notice texts follow; SPDX expressions are metadata, not a substitute for those texts. Generated with app/tools/Export-DependencyNotices.ps1.`n")
    foreach ($package in ($metadata.packages | Sort-Object name, version)) {
        if ($package.name -eq 'atlas-app') { continue }
        $root = Split-Path $package.manifest_path
        $files = @(Get-ChildItem -LiteralPath $root -Recurse -File | Where-Object {
            $_.Name -match '^(licen[cs]e|copying|notice|copyright)([._-]|$)' -and
            $_.FullName -notmatch '[\\/]\.git[\\/]'
        } | Sort-Object FullName)
        $texts = [System.Collections.Generic.List[object]]::new()
        foreach ($file in $files) {
            $body = [IO.File]::ReadAllText($file.FullName)
            # Crate archives sometimes contain flattened symlinks. They are not licenses.
            if ([string]::IsNullOrWhiteSpace($body) -or $body.Trim() -match '^\.\.?[/\\][^\r\n]+$') { continue }
            $texts.Add([ordered]@{ path = $file.FullName.Substring($root.Length + 1).Replace('\', '/'); sha256 = (Get-NoticeHash $body); text = $body.Replace("`r`n", "`n").TrimEnd() })
        }
        foreach ($extra in @($supplements | Where-Object { $_.package -eq $package.name -and $_.version -eq $package.version })) {
            $file = Join-Path $app "licenses/$($extra.file)"
            if ((Get-FileHash $file -Algorithm SHA256).Hash -ne $extra.sha256) { throw "Supplement hash mismatch: $file" }
            if ($extra.url -notmatch '/[0-9a-f]{40}/') { throw "Supplement source must pin a commit: $($extra.url)" }
            $texts.Add([ordered]@{ path = $extra.url; sha256 = $extra.sha256; text = [IO.File]::ReadAllText($file).Replace("`r`n", "`n").TrimEnd() })
        }
        if (-not $texts.Count -or -not $package.license) {
            $unresolved.Add("$($package.name) $($package.version)")
            $sections.Add("`nUNRESOLVED NOTICE: $($package.name) $($package.version). Declared license: $($package.license). This development inventory is not approved for executable distribution.`n")
        }
        $isNormal = $normal -contains "$($package.name) v$($package.version)"
        if ($null -eq $package.source) { $isNormal = $normal.Where({ $_ -like "$($package.name) v$($package.version) (*)" }).Count -gt 0 }
        $inventory.Add([ordered]@{ package = $package.name; version = $package.version; source = $package.source; license = $package.license; normalWindowsDependency = $isNormal; notices = @($texts | ForEach-Object { [ordered]@{ path = $_.path; sha256 = $_.sha256 } }) })
        $sections.Add("`n========================================================================`n$($package.name) $($package.version)`nDeclared license: $($package.license)`nRepository: $($package.repository)`n")
        foreach ($notice in $texts) { $sections.Add("`n--- $($notice.path) ---`n$($notice.text)`n") }
    }
    $outputs = @{
        'THIRD-PARTY-NOTICES.txt' = ($sections -join "`n") + "`n"
        'dependency-inventory.json' = (ConvertTo-Json -Depth 10 -InputObject ([ordered]@{ cargoLockSha256 = (Get-NoticeHash ([IO.File]::ReadAllText((Join-Path $app 'Cargo.lock')))); hashEncoding = 'UTF-8 with LF line endings; supplemental hashes retain downloaded bytes'; target = 'x86_64-pc-windows-msvc'; scope = 'conservative locked target resolution, including build and development packages'; unresolved = @($unresolved); packages = @($inventory) })) + "`n"
    }
    if ($unresolved.Count) {
        $message = "Unresolved notices: $($unresolved -join ', '). Review corresponding sources; do not substitute generic license templates."
        if ($Check) { throw $message }
        Write-Warning $message
    }
    foreach ($name in $outputs.Keys) {
        $path = Join-Path $app "licenses/$name"
        $expected = $outputs[$name].Replace("`r`n", "`n")
        if ($Check) {
            if (-not (Test-Path $path) -or [IO.File]::ReadAllText($path).Replace("`r`n", "`n") -cne $expected) { throw "Stale dependency notices: run app/tools/Export-DependencyNotices.ps1 ($name)." }
        } else { [IO.File]::WriteAllText($path, $expected, [Text.UTF8Encoding]::new($false)) }
    }
    Write-Output "Verified notices for $($inventory.Count) resolved dependency packages."
} finally { Pop-Location }
