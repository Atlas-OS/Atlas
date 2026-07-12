# Atlas.Toggles domain: upgrade and same-version reapply.
#
# Recorded choices are declarative machine state. Under strict TrustedInstaller, replay
# resolves each record against the installed definition and runs only its explicitly
# classified machine action. Per-user actions remain a first-logon concern.

function Invoke-AtlasToggleTrustedReapplyState {
    <#
    .SYNOPSIS
        Executes one resolved machine state inside the strict-TI replay phase.
    #>
    param(
        [Parameter(Mandatory = $true)]
        [ValidateNotNull()]
        $Definition,

        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [string]$StateName,

        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [string]$StateRoot
    )

    Assert-AtlasPrivilege -TrustedInstaller

    $exactStates = @($Definition.States.Keys | Where-Object {
            [string]::Equals([string]$_, $StateName, [StringComparison]::Ordinal)
        })
    if ($exactStates.Count -ne 1) {
        throw "Trusted replay state '$StateName' does not resolve exactly once for toggle '$($Definition.Name)'."
    }

    $stateEntry = $Definition.States[$exactStates[0]]
    $elevation = if ($Definition.Contains('Elevation')) {
        [string]$Definition.Elevation
    }
    else {
        'None'
    }
    if ($elevation -notin @('Admin', 'TrustedInstaller')) {
        throw "Trusted replay toggle '$($Definition.Name)' is not classified as privileged machine state."
    }

    if (Test-AtlasToggleSplitMachineState -StateEntry $stateEntry) {
        Invoke-AtlasToggleInProcess `
            -Definition $Definition `
            -StateName $StateName `
            -Silent `
            -NoExplorerRestart `
            -StateRoot $StateRoot `
            -ActionScope Machine
        return
    }

    if (-not $stateEntry.Contains('Action') -or
        $stateEntry.Action -isnot [scriptblock] -or
        -not $stateEntry.Contains('ReplayScope') -or
        [string]$stateEntry.ReplayScope -cne 'Machine') {
        throw "Trusted replay toggle '$($Definition.Name)' state '$StateName' is not classified as machine state."
    }

    Invoke-AtlasToggleInProcess `
        -Definition $Definition `
        -StateName $StateName `
        -Silent `
        -NoExplorerRestart `
        -StateRoot $StateRoot `
        -ActionScope Automatic
}

function Remove-AtlasToggleReplayRecord {
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute(
        'PSUseShouldProcessForStateChangingFunctions',
        '',
        Justification = 'This private cleanup runs only inside the strict-TI replay transaction.'
    )]
    param(
        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [string]$Name,

        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [string]$KeyPath,

        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [string]$Reason
    )

    Write-AtlasLog -Level Warning -Message "Toggle '$Name' $Reason Removing stale registry record."
    Remove-Item -LiteralPath $KeyPath -Recurse -Force -ErrorAction Stop
}

function Invoke-AtlasToggleReapply {
    <#
    .SYNOPSIS
        Replays recorded machine state from the currently installed toggle definitions.
    #>
    param(
        [ValidateNotNullOrEmpty()]
        [string]$StateRoot = $script:AtlasToggleDefaultStateRoot,

        # Overridable for tests; defaults to the installed Toggles directory.
        [string]$TogglesRoot
    )

    Assert-AtlasPrivilege -TrustedInstaller
    if (-not (Test-Path -LiteralPath $StateRoot)) {
        Write-AtlasLog -Level Warning -Message "Registry path '$StateRoot' not found, skipping."
        return
    }

    Protect-AtlasToggleStateRoot -StateRoot $StateRoot -IncludeChildren
    $failures = @()

    foreach ($subkey in @(Get-ChildItem -LiteralPath $StateRoot -ErrorAction Stop)) {
        $name = [string]$subkey.PSChildName
        $definition = $null
        $recordedState = $null
        $stateName = $null

        try {
            $properties = Get-ItemProperty -LiteralPath $subkey.PSPath -ErrorAction Stop
            if ($null -eq $properties -or
                -not $properties.PSObject.Properties['state'] -or
                $subkey.GetValueKind('state') -ne [Microsoft.Win32.RegistryValueKind]::DWord) {
                throw 'has no REG_DWORD state.'
            }
            $recordedState = [int]$properties.state

            $definition = Get-AtlasToggleDefinition -Name $name -TogglesRoot $TogglesRoot
            if ($definition.Contains('NoStateRecord') -and $definition.NoStateRecord) {
                throw 'belongs to a definition that no longer records state.'
            }

            $matchingStates = @($definition.States.Keys | Where-Object {
                    $entry = $definition.States[$_]
                    $entry.Contains('StateValue') -and
                        [int]$entry.StateValue -eq $recordedState
                })
            if ($matchingStates.Count -ne 1) {
                throw "state '$recordedState' does not map to exactly one installed state."
            }

            $stateName = [string]$matchingStates[0]
            $stateEntry = $definition.States[$stateName]
            if ($stateEntry.Contains('NoStateRecord') -and $stateEntry.NoStateRecord) {
                throw "state '$stateName' no longer records state."
            }
        }
        catch {
            Remove-AtlasToggleReplayRecord `
                -Name $name `
                -KeyPath $subkey.PSPath `
                -Reason $_.Exception.Message
            continue
        }

        Remove-AtlasToggleLegacyPath -KeyPath $subkey.PSPath
        if ($recordedState -eq 0) {
            continue
        }

        $stateEntry = $definition.States[$stateName]
        $isSplitMachine = Test-AtlasToggleSplitMachineState -StateEntry $stateEntry
        $isExplicitMachine = $stateEntry.Contains('Action') -and
            $stateEntry.Action -is [scriptblock] -and
            $stateEntry.Contains('ReplayScope') -and
            [string]$stateEntry.ReplayScope -ceq 'Machine'
        if (-not $isSplitMachine -and -not $isExplicitMachine) {
            Write-AtlasLog -Level Warning -Message `
                "Toggle '$name' state '$stateName' is not classified for machine replay; leaving its record unchanged."
            continue
        }

        Write-AtlasLog -Message "Re-applying toggle '$name' machine state '$stateName'."
        try {
            Invoke-AtlasToggleTrustedReapplyState `
                -Definition $definition `
                -StateName $stateName `
                -StateRoot $StateRoot
        }
        catch {
            $failureMessage = $_.Exception.Message
            Write-AtlasLog -Level Warning -Message `
                "Re-applying toggle '$name' failed: $failureMessage" -ErrorRecord $_
            $failures += [pscustomobject]@{
                Name    = $name
                Message = [string]$failureMessage
            }
        }
    }

    if ($failures.Count -gt 0) {
        $failureDetails = @($failures | ForEach-Object {
                "'$($_.Name)': $($_.Message)"
            }) -join '; '
        throw "Upgrade toggle re-apply failed for $($failures.Count) toggle(s): $failureDetails"
    }
}
