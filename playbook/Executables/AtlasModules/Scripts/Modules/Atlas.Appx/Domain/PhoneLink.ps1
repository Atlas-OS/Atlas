# Atlas.Appx domain: Phone Link removal.
#
# Removing Microsoft.YourPhone with AME Wizard causes issues with Cross Device
# Experience Host installing, so it is removed with the AppX cmdlets instead
# (formerly Tasks\Remove-PhoneLinkAppx.ps1).

function Remove-AtlasPhoneLinkAppx {
    <#
    .SYNOPSIS
        Removes the Phone Link (Microsoft.YourPhone) AppX package for all users and
        removes its provisioned package.
    #>
    Get-AppxPackage -Name 'Microsoft.YourPhone*' | Remove-AppxPackage -ErrorAction Stop
    Get-AppxProvisionedPackage -Online |
        Where-Object { $_.DisplayName -eq 'Microsoft.YourPhone' } |
        Remove-AppxProvisionedPackage -Online -ErrorAction Stop | Out-Null
}
