[CmdletBinding()]
param()

$ErrorActionPreference = 'Stop'

try {
    $downloadIntegrity = [IO.Path]::Combine($PSScriptRoot, 'Download-Integrity.ps1')
    if (-not [IO.File]::Exists($downloadIntegrity)) {
        throw "The Atlas download-integrity helper is missing at '$downloadIntegrity'."
    }
    . $downloadIntegrity

    $wingetPath = Get-AtlasTrustedWingetPath
    Assert-AtlasTrustedWingetSource -WingetPath $wingetPath -Name winget
    & $wingetPath show --exact --id 'Microsoft.VisualStudioCode' --source winget --accept-source-agreements --disable-interactivity *> $null
    if ($LASTEXITCODE -ne 0) {
        exit 1
    }
    exit 0
}
catch {
    Write-Error $_ -ErrorAction Continue
    exit 1
}
