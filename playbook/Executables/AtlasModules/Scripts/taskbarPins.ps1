param (
    [string]$Browser
)

$internalScript = Join-Path -Path $PSScriptRoot -ChildPath 'Internal\TaskbarPins.ps1'
if (-not (Test-Path -LiteralPath $internalScript -PathType Leaf)) {
    Write-Error "Atlas internal taskbar pin script '$internalScript' is missing."
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
