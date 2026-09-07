<#
.SYNOPSIS
    Compiles the Atlas native surface (Atlas.Native.cs) into Atlas.Native.dll.
.DESCRIPTION
    The payload compiles Scripts\Modules\Atlas.Core\Native\Atlas.Native.cs at runtime with
    Add-Type, once per process, through a protected compiler directory. This tool builds
    the same source ahead of time so the assembly can be signed and shipped beside the
    source; Initialize-AtlasNativeType loads a DLL with a valid Authenticode signature
    instead of compiling.

    The compiler is the Roslyn csc.exe from a Visual Studio or Build Tools installation
    (found through vswhere) or the one given with -CompilerPath. Roslyn builds are
    deterministic: the same source and compiler produce byte-identical output, which is
    what lets a reviewer rebuild and compare a released DLL. The legacy .NET Framework
    csc.exe (v4.0.30319) is accepted with -AllowLegacyCompiler for a quick local check
    but its output is not reproducible and must not be shipped.

    Without -SignCertificateThumbprint the DLL is left unsigned and the payload keeps
    compiling from source. Shipping a DLL requires a code-signing certificate that the
    project does not have yet; this tool is the complete build step for when it does.
.PARAMETER OutputPath
    Directory for Atlas.Native.dll and Atlas.Native.dll.sha256. Defaults to
    artifacts\native under the repository root.
.PARAMETER CompilerPath
    Explicit csc.exe to use.
.PARAMETER SignCertificateThumbprint
    Thumbprint of a code-signing certificate in CurrentUser\My or LocalMachine\My. The
    DLL is signed with SHA-256 and timestamped.
.PARAMETER TimestampServer
    RFC 3161 timestamp server used when signing.
.PARAMETER AllowLegacyCompiler
    Fall back to the .NET Framework csc.exe when no Roslyn compiler is found.
.EXAMPLE
    .\Build-AtlasNative.ps1
    .\Build-AtlasNative.ps1 -SignCertificateThumbprint 0123ABCD...
.NOTES
    Exit codes: 0 built, 1 build or signing failed, 2 no usable compiler.
#>
#Requires -Version 7.0
[CmdletBinding()]
param(
    [string]$OutputPath,

    [string]$CompilerPath,

    [ValidatePattern('^[0-9A-Fa-f]{40}$')]
    [string]$SignCertificateThumbprint,

    [string]$TimestampServer = 'http://timestamp.digicert.com',

    [switch]$AllowLegacyCompiler
)

Set-StrictMode -Version 3.0
$ErrorActionPreference = 'Stop'

$repoRoot = (Resolve-Path -LiteralPath (Join-Path -Path $PSScriptRoot -ChildPath '..\..')).Path
$sourcePath = Join-Path -Path $repoRoot -ChildPath 'playbook\Executables\AtlasModules\Scripts\Modules\Atlas.Core\Native\Atlas.Native.cs'
if (-not $OutputPath) {
    $OutputPath = Join-Path -Path $repoRoot -ChildPath 'artifacts\native'
}
if (-not (Test-Path -LiteralPath $sourcePath -PathType Leaf)) {
    [Console]::Error.WriteLine("The native source '$sourcePath' is missing.")
    exit 1
}

function Find-RoslynCompiler {
    <#
    .SYNOPSIS
        Locates the newest Roslyn csc.exe through vswhere, or returns $null.
    #>
    $vswhere = Join-Path -Path ${env:ProgramFiles(x86)} -ChildPath 'Microsoft Visual Studio\Installer\vswhere.exe'
    if (-not (Test-Path -LiteralPath $vswhere -PathType Leaf)) {
        return $null
    }
    $found = & $vswhere -latest -products '*' -requires Microsoft.Component.MSBuild -find 'MSBuild\**\Roslyn\csc.exe' 2>$null
    if ($LASTEXITCODE -ne 0 -or -not $found) {
        return $null
    }
    return ([string[]]$found)[0]
}

function Get-FrameworkReference {
    <#
    .SYNOPSIS
        Returns the .NET Framework 4 reference assemblies the source needs, from the
        installed runtime directory, so the DLL targets exactly what Windows PowerShell
        5.1 loads.
    #>
    $runtime = Join-Path -Path $env:windir -ChildPath 'Microsoft.NET\Framework64\v4.0.30319'
    return @('mscorlib.dll', 'System.dll', 'System.Core.dll') | ForEach-Object { Join-Path -Path $runtime -ChildPath $_ }
}

$legacy = $false
if (-not $CompilerPath) {
    $CompilerPath = Find-RoslynCompiler
    if (-not $CompilerPath -and $AllowLegacyCompiler) {
        $CompilerPath = Join-Path -Path $env:windir -ChildPath 'Microsoft.NET\Framework64\v4.0.30319\csc.exe'
        $legacy = $true
    }
}
if (-not $CompilerPath -or -not (Test-Path -LiteralPath $CompilerPath -PathType Leaf)) {
    [Console]::Error.WriteLine('No Roslyn csc.exe was found. Install Visual Studio Build Tools, pass -CompilerPath, or use -AllowLegacyCompiler for a non-reproducible local build.')
    exit 2
}
if (-not $legacy -and $CompilerPath -like "*\Microsoft.NET\Framework*\csc.exe") {
    $legacy = $true
}

New-Item -Path $OutputPath -ItemType Directory -Force | Out-Null
$dllPath = Join-Path -Path $OutputPath -ChildPath 'Atlas.Native.dll'
$hashPath = "$dllPath.sha256"
Remove-Item -LiteralPath $dllPath, $hashPath -Force -ErrorAction SilentlyContinue

$references = Get-FrameworkReference | ForEach-Object { "/reference:$_" }
$arguments = @(
    '/nologo'
    '/target:library'
    '/optimize+'
    '/warnaserror+'
    '/nostdlib+'
    '/langversion:5'
    "/out:$dllPath"
) + $references
if (-not $legacy) {
    $arguments += '/deterministic+'
    $arguments += "/pathmap:$repoRoot=."
    $arguments += '/debug-'
}
$arguments += $sourcePath

Write-Host "Compiler: $CompilerPath$(if ($legacy) { ' (legacy, output is not reproducible)' })"
& $CompilerPath @arguments
if ($LASTEXITCODE -ne 0 -or -not (Test-Path -LiteralPath $dllPath -PathType Leaf)) {
    [Console]::Error.WriteLine("Compiling '$sourcePath' failed (exit code $LASTEXITCODE).")
    exit 1
}

if ($SignCertificateThumbprint) {
    $certificate = @(Get-ChildItem -Path 'Cert:\CurrentUser\My', 'Cert:\LocalMachine\My' -ErrorAction SilentlyContinue |
            Where-Object { $_.Thumbprint -eq $SignCertificateThumbprint }) | Select-Object -First 1
    if (-not $certificate) {
        [Console]::Error.WriteLine("No certificate with thumbprint '$SignCertificateThumbprint' is installed.")
        exit 1
    }
    $signature = Set-AuthenticodeSignature -FilePath $dllPath -Certificate $certificate -HashAlgorithm SHA256 -TimestampServer $TimestampServer
    if ($signature.Status -ne 'Valid') {
        [Console]::Error.WriteLine("Signing failed: $($signature.StatusMessage)")
        exit 1
    }
    Write-Host "Signed with '$($certificate.Subject)'."
}
else {
    Write-Host 'Unsigned: the payload will keep compiling from source until a signed DLL ships.'
}

$hash = (Get-FileHash -LiteralPath $dllPath -Algorithm SHA256).Hash.ToLowerInvariant()
[IO.File]::WriteAllText($hashPath, "$hash *Atlas.Native.dll`n", (New-Object System.Text.UTF8Encoding($false)))
Write-Host "Built: $dllPath"
Write-Host "SHA256: $hash"
exit 0
