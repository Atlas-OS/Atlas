# Compile the complete patched GPUI shader with the same entrypoints/profiles
# used by production. Output stays in a unique temporary directory.
[CmdletBinding()]
param([string]$FxcPath)
$ErrorActionPreference = 'Stop'
if (-not $FxcPath) {
    if ($env:GPUI_FXC_PATH) { $FxcPath = $env:GPUI_FXC_PATH }
    else {
        $sdk = Join-Path ${env:ProgramFiles(x86)} 'Windows Kits/10/bin'
        $FxcPath = Get-ChildItem -LiteralPath $sdk -Filter fxc.exe -Recurse |
            Where-Object { $_.FullName -match '\\x64\\' } |
            Sort-Object FullName -Descending | Select-Object -First 1 -ExpandProperty FullName
    }
}
if (-not $FxcPath) { throw 'Set -FxcPath or GPUI_FXC_PATH to the Windows SDK shader compiler.' }
$shader = Join-Path $PSScriptRoot '../vendor/gpui-pre-windows/src/shaders.hlsl'
$output = Join-Path ([IO.Path]::GetTempPath()) ('atlas-shader-check-' + [guid]::NewGuid().ToString('N'))
New-Item -ItemType Directory -Path $output | Out-Null
$count = 0
foreach ($module in @('quad','shadow','path_rasterization','path_sprite','underline','monochrome_sprite','subpixel_sprite','polychrome_sprite')) {
    foreach ($stage in @(@('vertex','vs_4_1'),@('fragment','ps_4_1'))) {
        $entry = "$($module)_$($stage[0])"
        $messages = & $FxcPath /nologo /O3 /T $stage[1] /E $entry /Fo (Join-Path $output "$entry.cso") $shader 2>&1
        if ($LASTEXITCODE) { throw "$entry failed:`n$($messages -join "`n")" }
        $count++
    }
}
"Compiled $count production shader entrypoints. Bytecode: $output"
