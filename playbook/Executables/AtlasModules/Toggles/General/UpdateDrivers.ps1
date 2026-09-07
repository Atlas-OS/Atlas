function Invoke-AtlasDriverUpdate {
    param($Toggle)

    $script = Join-Path -Path $Toggle.OperationsPath -ChildPath 'Update-Drivers.ps1'
    if (-not (Test-Path -LiteralPath $script -PathType Leaf)) {
        throw "The driver update script is missing at '$script'."
    }

    # The updater prints through the shared vocabulary and leaves the exit pause to
    # the engine; its exit code decides whether this run counts as done.
    $global:LASTEXITCODE = 0
    & $script -Silent:([bool]$Toggle.Silent)
    if ($LASTEXITCODE -ne 0) {
        throw "The driver updater did not complete (exit code $LASTEXITCODE)."
    }
}
