# Atlas.Appx domain: Xbox Game Bar installation.

function Install-AtlasGameBar {
    <#
    .SYNOPSIS
        Installs Xbox Game Bar from the Microsoft Store through the trusted WinGet
        client, treating "already installed" as success.
    .DESCRIPTION
        Runs as the signed-in user because Store installs register for that account.
        A Game Bar already registered and working for the account is left as it is,
        so replaying the choice at sign-in reaches neither WinGet nor the Store.
        WinGet reports 0x8A15002B when the package is installed and no applicable
        upgrade exists; any other non-zero exit code fails the install.
    #>
    $installed = @(Get-AppxPackage -Name Microsoft.XboxGamingOverlay -ErrorAction SilentlyContinue |
            Where-Object { [string]$_.Status -eq 'Ok' })
    if ($installed.Count -gt 0) {
        Write-AtlasLog -Message 'Xbox Game Bar is already installed for this account.'
        return
    }
    $wingetPath = Get-AtlasTrustedWingetPath
    Assert-AtlasTrustedWingetSource -WingetPath $wingetPath -Name msstore
    & $wingetPath install --exact --id 9NZKPSTSNW4P --source msstore `
        --accept-package-agreements --accept-source-agreements --disable-interactivity --silent
    $exitCode = [BitConverter]::ToUInt32([BitConverter]::GetBytes([int]$LASTEXITCODE), 0)
    $noApplicableUpgrade = [Convert]::ToUInt32('8A15002B', 16)
    if ($exitCode -eq $noApplicableUpgrade) {
        Write-AtlasLog -Message 'Xbox Game Bar is already installed and no applicable upgrade is available.'
    }
    elseif ($exitCode -ne 0) {
        throw "WinGet failed to install Xbox Game Bar with exit code $LASTEXITCODE."
    }
}
