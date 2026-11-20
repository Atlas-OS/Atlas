# Companion for the FSOGameBar toggle: removes the Game Bar overlay package for every user, or
# installs Game Bar again for one account. Remove-AtlasGameBarOverlayPackage runs in the
# silent TrustedInstaller broker when you run Disable and when an update replays the recorded
# state. Install-AtlasGameBarPackage runs in your own unelevated process when you run Enable,
# and is replayed for each new account at first sign-in.

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
