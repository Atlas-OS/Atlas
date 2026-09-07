function Remove-AtlasGameBarOverlayPackage {
    param($Toggle)

    # Under TrustedInstaller/SYSTEM, -AllUsers is required on both commands.
    Get-AppxPackage -AllUsers '*xboxgamingoverlay*' -ErrorAction Stop |
        Remove-AppxPackage -AllUsers -Confirm:$false -ErrorAction Stop
}

function Install-AtlasGameBarPackage {
    param($Toggle)

    if (-not $Toggle.Silent) {
        Write-AtlasStep -Text 'Restoring the Game Bar package...'
    }
    Import-AtlasModule -Name Atlas.Appx
    Install-AtlasGameBar
}
