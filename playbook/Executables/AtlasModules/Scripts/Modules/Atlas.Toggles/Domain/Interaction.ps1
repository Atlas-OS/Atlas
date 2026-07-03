# Atlas.Toggles domain: interactive console helpers.

function Show-AtlasStateMenu {
    <#
    .SYNOPSIS
        Shows a numbered console menu over the states of a toggle definition and returns
        the chosen state name. Used by single-launcher multi-state (Menu) toggles.
    #>
    param(
        [Parameter(Mandatory = $true)]
        [ValidateNotNull()]
        $Definition
    )

    $stateNames = @($Definition.States.Keys)

    Write-Host ''
    Write-Host 'What would you like to do?'
    for ($index = 0; $index -lt $stateNames.Count; $index++) {
        $stateEntry = $Definition.States[$stateNames[$index]]
        $label = $stateNames[$index]
        if ($stateEntry.Contains('MenuLabel') -and $stateEntry.MenuLabel) {
            $label = [string]$stateEntry.MenuLabel
        }
        Write-Host ('[{0}] {1}' -f ($index + 1), $label)
    }
    Write-Host ''

    while ($true) {
        $answer = Read-Host ('Type a number between 1 and {0}' -f $stateNames.Count)
        $choice = 0
        if ([int]::TryParse($answer, [ref]$choice) -and $choice -ge 1 -and $choice -le $stateNames.Count) {
            return $stateNames[$choice - 1]
        }
        Write-Host 'Invalid choice, try again.' -ForegroundColor Yellow
    }
}
