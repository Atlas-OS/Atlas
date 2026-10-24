function Disable-AtlasSearchIndexing {
    param($Toggle)

    [void]$Toggle
    Import-AtlasModule -Name Atlas.Search
    Set-AtlasIndexingMachineState -State Disable
}

function Set-AtlasMinimalSearchIndexing {
    param($Toggle)

    [void]$Toggle
    Import-AtlasModule -Name Atlas.Search
    Set-AtlasIndexingMachineState -State Minimal
}

function Enable-AtlasSearchIndexing {
    param($Toggle)

    # TrustedInstaller work always runs silently, so the interactive power-mode
    # question is Select-AtlasFullIndexingState.
    [void]$Toggle
    Import-AtlasModule -Name Atlas.Search
    Set-AtlasIndexingMachineState -State Full -PreservePowerModes
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
