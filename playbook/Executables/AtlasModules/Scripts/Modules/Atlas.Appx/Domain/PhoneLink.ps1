# Atlas.Appx domain: Phone Link removal.
#
# Removing Microsoft.YourPhone with AME Wizard caused issues with Cross Device
# Experience Host installing, so it remains a separate, best-effort package-family
# plan that uses the AppX and DISM cmdlets directly.

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
