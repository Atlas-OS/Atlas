# Atlas.Registry domain: .reg file import.

function Import-AtlasRegFile {
    <#
    .SYNOPSIS
        Imports a .reg file via reg.exe, throwing on a non-zero exit code. Note that
        HKCU paths inside the file resolve to the ambient hive of the current process;
        use Set-AtlasRegistryValue for per-user data that must survive TrustedInstaller.
    #>
    param(
        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [string]$Path
    )

    if (-not (Test-Path -LiteralPath $Path -PathType Leaf)) {
        throw "Registry file not found: '$Path'."
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
