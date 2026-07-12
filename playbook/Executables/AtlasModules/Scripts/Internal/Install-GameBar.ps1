[CmdletBinding()]
param()

$ErrorActionPreference = 'Stop'

$downloadIntegrity = [IO.Path]::Combine($PSScriptRoot, 'Download-Integrity.ps1')
if (-not [IO.File]::Exists($downloadIntegrity)) {
    throw "The Atlas download-integrity helper is missing at '$downloadIntegrity'."
}
. $downloadIntegrity

$wingetPath = Get-AtlasTrustedWingetPath
Assert-AtlasTrustedWingetSource -WingetPath $wingetPath -Name msstore
& $wingetPath install --exact --id 9NZKPSTSNW4P --source msstore `
    --accept-package-agreements --accept-source-agreements --disable-interactivity --silent
if ($LASTEXITCODE -ne 0) {
    throw "WinGet failed to install Xbox Game Bar with exit code $LASTEXITCODE."
}
