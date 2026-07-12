# Atlas.Registry domain: .reg file import.

function Import-AtlasRegFile {
    <#
    .SYNOPSIS
        Imports a .reg file via reg.exe, throwing on a non-zero exit code. HKCU paths
        cannot identify the intended interactive account under LocalSystem, so an HKCU
        import in that context is rejected. Use typed registry functions in an exact-user
        process, or explicitly bind them to Atlas's loaded default-user hive.
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
            throw "Registry file '$Path' contains HKCU sections; Atlas.Registry cannot select an interactive user for a .reg import under LocalSystem."
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
