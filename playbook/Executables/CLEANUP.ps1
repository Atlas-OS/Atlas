$internalScript = Join-Path -Path $PSScriptRoot -ChildPath 'AtlasModules\Scripts\Internal\Cleanup.ps1'
if (-not (Test-Path -LiteralPath $internalScript -PathType Leaf)) {
    Write-Error "Atlas internal cleanup script '$internalScript' is missing."
    exit 1
}

& $internalScript @args
if (-not $?) {
    exit 1
}

if ($null -ne $LASTEXITCODE) {
    exit $LASTEXITCODE
}

exit 0
