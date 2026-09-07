function Disable-AtlasSearchIndexing {
    param($Toggle)

    Import-AtlasModule -Name Atlas.Search

    if (-not $Toggle.Silent) {
        Write-AtlasStep -Text 'Disabling search indexing...'
    }
    Set-AtlasIndexingMachineState -State Disable
}

function Set-AtlasMinimalSearchIndexing {
    param($Toggle)

    Import-AtlasModule -Name Atlas.Search

    if (-not $Toggle.Silent) {
        Write-AtlasStep -Text 'Configuring minimal search indexing (the Start menu and the Atlas folder only)...'
    }
    Set-AtlasIndexingMachineState -State Minimal
}

function Enable-AtlasSearchIndexing {
    param($Toggle)

    Import-AtlasModule -Name Atlas.Search

    if ($Toggle.Silent) {
        Set-AtlasIndexingMachineState -State Full -PreservePowerModes
        return
    }

    $respectPowerModes = 0
    if (Read-AtlasYesNo -Question 'Pause indexing while on battery power or gaming?') {
        $respectPowerModes = 1
    }
    Write-AtlasStep -Text 'Enabling full search indexing...'
    Set-AtlasIndexingMachineState -State Full -RespectPowerModes $respectPowerModes
}

function Select-AtlasFullIndexingState {
    param($Toggle)

    if ($Toggle.Silent) { throw 'Interactive indexing selection cannot run silently.' }
    if (Read-AtlasYesNo -Question 'Pause indexing while on battery power or gaming?') {
        return 'EnableRespectPowerModes'
    }
    return 'EnableIgnorePowerModes'
}

function Set-AtlasSelectedFullIndexing {
    param($Toggle)

    $value = switch -CaseSensitive ($Toggle.State) {
        'EnableRespectPowerModes' { 1 }
        'EnableIgnorePowerModes' { 0 }
        default { throw "Unexpected full indexing choice '$($Toggle.State)'." }
    }
    Import-AtlasModule -Name Atlas.Search
    Set-AtlasIndexingMachineState -State Full -RespectPowerModes $value
    # Both interactive variants become the existing replayable Full choice. Only
    # record after the preset and its selected power-mode setting both succeed.
    Set-AtlasToggleState -Name Indexing -State 2 -StateRoot $Toggle.StateRoot
}
