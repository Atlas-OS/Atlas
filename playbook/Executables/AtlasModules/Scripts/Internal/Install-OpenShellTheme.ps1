[CmdletBinding()]
param()

$ErrorActionPreference = 'Stop'

$downloadIntegrity = [IO.Path]::Combine($PSScriptRoot, 'Download-Integrity.ps1')
if (-not [IO.File]::Exists($downloadIntegrity)) {
    throw "The Atlas download-integrity helper is missing at '$downloadIntegrity'."
}
. $downloadIntegrity

$transactionHelper = [IO.Path]::Combine($PSScriptRoot, 'OpenShell-ThemeTransaction.ps1')
if (-not [IO.File]::Exists($transactionHelper)) {
    throw "The Open-Shell theme transaction helper is missing at '$transactionHelper'."
}
. $transactionHelper

# Fluent Metro does not publish a signed archive or a GitHub release-asset
# digest. Pin the reviewed release and SHA-256 together.
$fluentMetroVersion = '1.5.3'
$fluentMetroSha256 = '7d50f7deac9af1c60640d7b40a7bc9b7e68ade421237a293958c4bcb03f6b868'
$fluentMetroBytes = 200916
$fluentMetroUri = "https://github.com/bonzibudd/Fluent-Metro/releases/download/v$fluentMetroVersion/Fluent-Metro_$fluentMetroVersion.zip"
$fluentMetroFiles = @(
    [pscustomobject]@{
        Name = 'Fluent-Metro.skin'
        Length = 545065
        Sha256 = 'd6fd55cec15b9936978557781b5e3f2e46dac5d26269b785bf97c8730412e205'
    }
    [pscustomobject]@{
        Name = 'Fluent-Metro.skin7'
        Length = 712097
        Sha256 = '7c6d7f878f0a8b43da09b04575000b30abb9a25515aaf1551c2c7c7e6046f706'
    }
    [pscustomobject]@{
        Name = 'Tiles.xml'
        Length = 8504
        Sha256 = '32c4818d3fc5f080cfd289cf2190d2244c7b4bb033330be1675867abfc4feacb'
    }
)
$stagingDirectory = New-AtlasProtectedStagingDirectory

try {
    $archive = Join-Path -Path $stagingDirectory -ChildPath 'Fluent-Metro.zip'
    Invoke-AtlasPinnedDownload -Uri $fluentMetroUri -Destination $archive `
        -Sha256 $fluentMetroSha256 -ExpectedBytes $fluentMetroBytes -MaximumSeconds 60 | Out-Null

    $extractedDirectory = Join-Path -Path $stagingDirectory -ChildPath 'extracted'
    [void](New-Item -Path $extractedDirectory -ItemType Directory -ErrorAction Stop)
    Expand-Archive -LiteralPath $archive -DestinationPath $extractedDirectory -Force

    $programFiles = [Environment]::GetFolderPath(
        [Environment+SpecialFolder]::ProgramFiles
    )
    $openShellDirectory = [IO.Path]::Combine($programFiles, 'Open-Shell')
    $skinsDirectory = [IO.Path]::Combine($openShellDirectory, 'Skins')
    Assert-AtlasOpenShellThemeDirectory `
        -Path $openShellDirectory `
        -Description 'Open-Shell installation'
    Assert-AtlasOpenShellThemeDirectory `
        -Path $skinsDirectory `
        -Description 'Open-Shell skins'
    Invoke-AtlasOpenShellThemeFileTransaction `
        -SourceDirectory $extractedDirectory `
        -SkinsDirectory $skinsDirectory `
        -ExpectedFiles $fluentMetroFiles
}
finally {
    if (Test-Path -LiteralPath $stagingDirectory -PathType Container) {
        Remove-Item -LiteralPath $stagingDirectory -Recurse -Force -ErrorAction SilentlyContinue
    }
}
