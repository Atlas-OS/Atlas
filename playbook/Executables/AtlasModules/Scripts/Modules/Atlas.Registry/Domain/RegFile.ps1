# Atlas.Registry domain: .reg file import.

function Import-AtlasRegFile {
    <#
    .SYNOPSIS
        Imports a .reg file via reg.exe, throwing on a non-zero exit code. HKCU paths
        cannot be redirected or represented in the typed Atlas mutation journal, so an
        HKCU import under LocalSystem is rejected. Use the typed registry
        functions for per-user data that must propagate to the default profile.
    #>
    param(
        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [string]$Path
    )

    if (-not (Test-Path -LiteralPath $Path -PathType Leaf)) {
        throw "Registry file not found: '$Path'."
    }

    if (Test-AtlasSystem) {
        $regFileContent = Get-Content -LiteralPath $Path -Raw -ErrorAction Stop
        if ($regFileContent -match '(?im)^\s*\[\s*-?\s*(?:HKEY_CURRENT_USER|HKCU)(?:\\|\s*\])') {
            throw "Registry file '$Path' contains HKCU sections; Atlas.Registry cannot redirect or journal HKCU mutations from a .reg import under LocalSystem."
        }
    }

    $regExePath = Join-Path -Path ([Environment]::GetFolderPath('System')) -ChildPath 'reg.exe'
    $previousErrorActionPreference = $ErrorActionPreference
    $ErrorActionPreference = 'Continue'
    try {
        $output = & $regExePath import "$Path" 2>&1
    }
    finally {
        $ErrorActionPreference = $previousErrorActionPreference
    }
    if ($LASTEXITCODE -ne 0) {
        $details = (@($output) | ForEach-Object { "$_" }) -join ' '
        throw "reg.exe import failed for '$Path' (exit code $LASTEXITCODE): $details"
    }
}
