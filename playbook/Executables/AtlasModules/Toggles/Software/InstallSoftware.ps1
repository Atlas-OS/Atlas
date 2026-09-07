function Invoke-AtlasSoftwarePicker {
    param($Toggle)

    $script = Join-Path -Path $Toggle.OperationsPath -ChildPath 'Install-Software.ps1'
    if (-not (Test-Path -LiteralPath $script -PathType Leaf)) {
        throw "InstallSoftware: the protected picker entry point is missing at '$script'."
    }

    # The picker exits 1 when WinGet is unavailable; that must not read as done.
    $global:LASTEXITCODE = 0
    & $script
    if ($LASTEXITCODE -ne 0) {
        throw 'WinGet is not available, so no software was installed. Install App Installer from the Microsoft Store, then try again.'
    }
}
