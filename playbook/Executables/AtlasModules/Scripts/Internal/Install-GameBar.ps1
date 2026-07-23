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
$exitCode = [BitConverter]::ToUInt32([BitConverter]::GetBytes([int]$LASTEXITCODE), 0)
$noApplicableUpgrade = [Convert]::ToUInt32('8A15002B', 16)
if ($exitCode -eq $noApplicableUpgrade) {
    Write-Output 'Xbox Game Bar is already installed and no applicable upgrade is available.'
}
elseif ($exitCode -ne 0) {
    throw "WinGet failed to install Xbox Game Bar with exit code $LASTEXITCODE."
}
