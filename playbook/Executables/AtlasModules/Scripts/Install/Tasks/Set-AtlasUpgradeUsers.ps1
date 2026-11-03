# The accounts Update-AtlasUser brings up to date at their next sign-in. The LegacyChoices
# step of an update stamps them with its version, and the installing user's setup on a
# reinstall of the same version with that version and its transaction, so each install
# reaches every account once.

function Set-AtlasUpgradeUserStamp {
    <#
    .SYNOPSIS
        Stamps every account in Windows's profile list with -Value, replacing the stamps
        an earlier install left. Update-AtlasUser runs once for each new stamp.
    #>
    param(
        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [string]$Value,

        # Tests point these at scratch keys.
        [ValidateNotNullOrEmpty()]
        [string]$Path = 'HKLM:\SOFTWARE\AtlasOS\UpgradeUsers',

        [ValidateNotNullOrEmpty()]
        [string]$ProfileListPath = 'HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\ProfileList'
    )

    $null = New-Item -Path $Path -Force
    foreach ($userProfile in Get-ChildItem -LiteralPath $ProfileListPath) {
        if ($userProfile.PSChildName -match '^S-1-(5-21|12-1)-\d+-\d+-\d+-\d+$') {
            New-ItemProperty -LiteralPath $Path -Name $userProfile.PSChildName -Value $Value -PropertyType String -Force | Out-Null
        }
    }
}
