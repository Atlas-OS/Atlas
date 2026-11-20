# Atlas.Toggles domain: interactive console helpers.

function Show-AtlasStateMenu {
    <#
    .SYNOPSIS
        Shows the numbered state menu of a Menu toggle and returns the chosen state
        name. The engine has already printed the heading.
    #>
    param(
        [Parameter(Mandatory = $true)]
        [ValidateNotNull()]
        $Definition
    )

    $stateNames = @($Definition.States.Keys)
    $labels = foreach ($stateName in $stateNames) {
        $stateEntry = $Definition.States[$stateName]
        if ($stateEntry.Contains('MenuLabel') -and $stateEntry.MenuLabel) {
            [string]$stateEntry.MenuLabel
        }
        else {
            [string]$stateName
        }
    }

    $choice = Read-AtlasChoice -Question 'What would you like to do?' -Option ([string[]]@($labels))
    return $stateNames[$choice - 1]
}
