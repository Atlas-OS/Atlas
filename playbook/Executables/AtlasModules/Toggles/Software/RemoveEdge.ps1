function Invoke-AtlasEdgeRemover {
    param($Toggle)

    $script = Join-Path -Path $Toggle.OperationsPath -ChildPath 'Remove-Edge.ps1'
    if (-not (Test-Path -LiteralPath $script -PathType Leaf)) {
        throw "Required Edge action helper is missing: '$script'."
    }
    if ($Toggle.Silent) {
        throw 'Installing or removing Microsoft Edge needs an interactive window to choose the action.'
    }

    # The engine's elevated window hosts the helper's menu and owns the heading and
    # the exit pause. The helper's exit code decides whether this run counts as done.
    $global:LASTEXITCODE = 0
    & $script -Embedded
    if ($LASTEXITCODE -ne 0) {
        throw "The Edge helper did not complete (exit code $LASTEXITCODE)."
    }
}
