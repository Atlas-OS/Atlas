param (
    [switch]$Chrome,
    [switch]$Brave,
    [switch]$Firefox,
    [switch]$Toolbox
)

$internalScript = Join-Path -Path $PSScriptRoot -ChildPath 'AtlasModules\Scripts\Internal\Software.ps1'
if (-not (Test-Path -LiteralPath $internalScript -PathType Leaf)) {
    Write-Error "Atlas internal software installer '$internalScript' is missing."
    exit 1
}

& $internalScript @PSBoundParameters
if (-not $?) {
    exit 1
}

if ($null -ne $LASTEXITCODE) {
    exit $LASTEXITCODE
}

exit 0
