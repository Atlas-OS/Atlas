#Requires -Version 7.2
# Build a portable executable for clean Windows installations. An explicit target
# keeps crt-static away from host build scripts and proc-macro DLLs.
#
# Without parameters this is the stable executable. -RcId and -EmbedApbx together
# build the tester variant that carries one playbook (the same environment and
# feature ../../tools/release/build-rc.sh uses); see docs/rc-testers-build.md.
[CmdletBinding()]
param(
    [switch]$Json,
    # The candidate id shown to testers, for example 0.6.0-rc.1.
    [string]$RcId,
    # The .apbx to bake into the executable.
    [string]$EmbedApbx
)

$ErrorActionPreference = 'Stop'
if ([string]::IsNullOrWhiteSpace($RcId) -ne [string]::IsNullOrWhiteSpace($EmbedApbx)) {
    throw 'Pass -RcId and -EmbedApbx together (a tester build), or neither (the stable build).'
}
$tester = -not [string]::IsNullOrWhiteSpace($RcId)
if ($tester) {
    # Resolve before changing directory: the path is relative to the caller.
    if (-not (Test-Path -LiteralPath $EmbedApbx -PathType Leaf)) { throw "-EmbedApbx does not name a file: $EmbedApbx" }
    $EmbedApbx = (Resolve-Path -LiteralPath $EmbedApbx).ProviderPath
}

$previous = @{
    CARGO_TARGET_X86_64_PC_WINDOWS_MSVC_RUSTFLAGS = $env:CARGO_TARGET_X86_64_PC_WINDOWS_MSVC_RUSTFLAGS
    CARGO_INCREMENTAL = $env:CARGO_INCREMENTAL
    ATLAS_EMBED_APBX = $env:ATLAS_EMBED_APBX
    ATLAS_RC_ID = $env:ATLAS_RC_ID
}
Push-Location (Split-Path -Parent $PSScriptRoot)
try {
    & (Join-Path $PSScriptRoot 'Export-DependencyNotices.ps1') -Check
    $env:CARGO_TARGET_X86_64_PC_WINDOWS_MSVC_RUSTFLAGS = '-C target-feature=+crt-static'
    # Stale incremental state has produced link failures in release builds.
    $env:CARGO_INCREMENTAL = '0'
    $buildArguments = @('build', '--release', '--locked', '--target', 'x86_64-pc-windows-msvc')
    if ($tester) {
        $env:ATLAS_EMBED_APBX = $EmbedApbx
        $env:ATLAS_RC_ID = $RcId
        $buildArguments += @('--features', 'embedded-playbook')
    }
    if ($Json) { $buildArguments += '--message-format=json-render-diagnostics' }
    cargo @buildArguments
    if ($LASTEXITCODE -ne 0) { throw "Atlas Manager release build failed ($LASTEXITCODE)." }
}
finally {
    foreach ($name in $previous.Keys) {
        [Environment]::SetEnvironmentVariable($name, $previous[$name], 'Process')
    }
    Pop-Location
}
