# Atlas.Appx domain: Phone Link removal.
#
# Removing Microsoft.YourPhone in the same plan as the other packages can stop Cross
# Device Experience Host from installing, so Phone Link has its own removal plan. The
# install runs it after the main plan and treats a failure as a warning.

function Remove-AtlasPhoneLinkAppx {
    <#
    .SYNOPSIS
        Removes Phone Link registrations for existing users and its provisioned
        package for future users, verifying both inventories.
    #>
    Invoke-AtlasAppxRemovalPlan -Definition @(
        [pscustomobject]@{
            Name         = 'Microsoft.YourPhone*'
            Option       = $null
            IgnoreErrors = $false
        }
    )
}
