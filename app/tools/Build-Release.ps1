#Requires -Version 7.2
# Build a portable executable for clean Windows installations. An explicit target
# keeps crt-static away from host build scripts and proc-macro DLLs.
[CmdletBinding()]
param([switch]$Json)

$ErrorActionPreference = 'Stop'
$previousFlags = $env:CARGO_TARGET_X86_64_PC_WINDOWS_MSVC_RUSTFLAGS
Push-Location (Split-Path -Parent $PSScriptRoot)
try {
    & (Join-Path $PSScriptRoot 'Export-DependencyNotices.ps1') -Check
    $env:CARGO_TARGET_X86_64_PC_WINDOWS_MSVC_RUSTFLAGS = '-C target-feature=+crt-static'
    $buildArguments = @('build', '--release', '--locked', '--target', 'x86_64-pc-windows-msvc')
    if ($Json) { $buildArguments += '--message-format=json-render-diagnostics' }
    cargo @buildArguments
    if ($LASTEXITCODE -ne 0) { throw "Atlas Manager release build failed ($LASTEXITCODE)." }
}
finally {
    $env:CARGO_TARGET_X86_64_PC_WINDOWS_MSVC_RUSTFLAGS = $previousFlags
    Pop-Location
}
