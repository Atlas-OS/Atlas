#Requires -Version 7.0
# Build reviewed timer sources without executing the resulting utilities.
# Requires PowerShell 7, git, MSVC 14.44.35207 and Windows SDK 10.0.26100.0.
[CmdletBinding()]
param(
    [Parameter(Mandatory)][string]$OutputDirectory,
    [string]$VisualStudio = "${env:ProgramFiles(x86)}\Microsoft Visual Studio\2022\BuildTools",
    [string]$WindowsKits = "${env:ProgramFiles(x86)}\Windows Kits\10"
)
$ErrorActionPreference = 'Stop'
$output = [IO.Path]::GetFullPath($OutputDirectory)
if (Test-Path -LiteralPath $output) { throw 'Choose a new output directory; existing candidates are never overwritten.' }
$vc = Join-Path $VisualStudio 'VC/Tools/MSVC/14.44.35207'
$compiler = Join-Path $vc 'bin/Hostx64/x64/cl.exe'
$sdkVersion = '10.0.26100.0'
if (-not (Test-Path $compiler) -or -not (Test-Path (Join-Path $WindowsKits "Include/$sdkVersion/um/Windows.h"))) { throw 'Install the declared compiler and SDK through your normal build environment provisioning.' }
New-Item -ItemType Directory -Path $output | Out-Null
$source = New-Item -ItemType Directory -Path (Join-Path $output 'source')
$inputs = Get-Content (Join-Path $PSScriptRoot 'inputs.json') -Raw | ConvertFrom-Json
foreach ($inputFile in $inputs) {
    $destination = Join-Path $source.FullName $inputFile.name
    Invoke-WebRequest -Uri $inputFile.url -OutFile $destination
    if ((Get-FileHash $destination -Algorithm SHA256).Hash -ne $inputFile.sha256) { throw "Pinned input hash mismatch: $($inputFile.name)" }
}
Copy-Item -LiteralPath (Join-Path $PSScriptRoot 'inputs.json'), (Join-Path $PSScriptRoot 'MeasureSleep.patch'), (Join-Path $PSScriptRoot 'SetTimerResolution.patch'), $PSCommandPath -Destination $source.FullName
$previousInclude = $env:INCLUDE
$previousLib = $env:LIB
$compilerOptions = @{}
foreach ($name in 'CL', '_CL_', 'LINK', '_LINK_') {
    $compilerOptions[$name] = [Environment]::GetEnvironmentVariable($name, 'Process')
    [Environment]::SetEnvironmentVariable($name, $null, 'Process')
}
Push-Location $source.FullName
try {
    foreach ($patch in 'MeasureSleep.patch', 'SetTimerResolution.patch') {
        & git apply --check $patch
        if ($LASTEXITCODE) { throw "Timer source patch no longer applies: $patch" }
        & git apply $patch
        if ($LASTEXITCODE) { throw "Could not apply reviewed timer patch: $patch" }
    }
    $env:INCLUDE = "$vc\include;$WindowsKits\Include\$sdkVersion\ucrt;$WindowsKits\Include\$sdkVersion\shared;$WindowsKits\Include\$sdkVersion\um"
    $env:LIB = "$vc\lib\x64;$WindowsKits\Lib\$sdkVersion\ucrt\x64;$WindowsKits\Lib\$sdkVersion\um\x64"
    foreach ($name in 'SetTimerResolution', 'MeasureSleep') {
        & $compiler /nologo /std:c++20 /O2 /MT /EHsc /DUNICODE /D_UNICODE /DNDEBUG /Brepro "$name.cpp" "/Fo:$output\$name.obj" "/Fe:$output\$name.exe" /link /Brepro ntdll.lib advapi32.lib
        if ($LASTEXITCODE) { throw "Timer compilation failed: $name" }
    }
    $manifest = [ordered]@{
        compilerVersion = (Get-Item $compiler).VersionInfo.FileVersion
        compilerSha256 = (Get-FileHash $compiler -Algorithm SHA256).Hash
        toolset = '14.44.35207'; windowsSdk = $sdkVersion
        flags = '/std:c++20 /O2 /MT /EHsc /DUNICODE /D_UNICODE /DNDEBUG /Brepro /link /Brepro ntdll.lib advapi32.lib'
        inputs = $inputs
        sourceFiles = @(Get-ChildItem -LiteralPath $source.FullName -File | Sort-Object Name | ForEach-Object { [ordered]@{ name = $_.Name; sha256 = (Get-FileHash $_.FullName -Algorithm SHA256).Hash } })
        outputs = @(Get-ChildItem -LiteralPath $output -Filter '*.exe' | Sort-Object Name | ForEach-Object { [ordered]@{ name = $_.Name; sha256 = (Get-FileHash $_.FullName -Algorithm SHA256).Hash } })
    }
    $manifest | ConvertTo-Json -Depth 6 | Set-Content -LiteralPath (Join-Path $output 'build-manifest.json') -Encoding utf8
    Compress-Archive -LiteralPath $source.FullName -DestinationPath (Join-Path $output 'corresponding-source.zip')
    Write-Output "Built unexecuted candidates in $output. Review the manifest and validate behavior before accepting payload replacements."
} finally {
    $env:INCLUDE = $previousInclude
    $env:LIB = $previousLib
    foreach ($name in $compilerOptions.Keys) { [Environment]::SetEnvironmentVariable($name, $compilerOptions[$name], 'Process') }
    Pop-Location
}
