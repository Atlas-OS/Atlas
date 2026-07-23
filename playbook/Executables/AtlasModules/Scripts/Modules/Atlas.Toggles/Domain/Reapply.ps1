# Atlas.Toggles domain: upgrade and same-version reapply.
#
# Recorded choices are declarative machine state. Under strict TrustedInstaller, replay
# resolves each record against the installed definition and runs only its explicitly
# classified machine action. Split per-user actions are replayed separately in the
# affected user's non-elevated first-logon context.

function New-AtlasToggleStaleReplayRecordException {
    param(
        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [string]$Message
    )

    $exception = [System.IO.InvalidDataException]::new($Message)
    $exception.Data['AtlasToggleReplayRecordDisposition'] = 'Stale'
    return $exception
}

function Get-AtlasToggleReplayDefinition {
    param(
        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [string]$Name,

        [string]$TogglesRoot
    )

    $root = Get-AtlasToggleRoot -TogglesRoot $TogglesRoot
    if (-not (Test-Path -LiteralPath $root -PathType Container)) {
        throw "Toggle definitions root '$root' does not exist."
    }

    $files = @(Get-ChildItem -LiteralPath $root -Recurse -File -Filter "$Name.ps1" `
        -ErrorAction Stop | Where-Object { $_.BaseName -ceq $Name })
    if ($files.Count -eq 0) {
        throw (New-AtlasToggleStaleReplayRecordException `
                -Message "has no installed toggle definition named '$Name'.")
    }
    if ($files.Count -gt 1) {
        throw "Multiple toggle definitions named '$Name' were found under '$root': $(($files | ForEach-Object { $_.FullName }) -join ', ')."
    }

    # Loading or validating an installed definition is operational work. Those failures
    # must preserve the user's record so a corrected payload can replay it later.
    $definition = & $files[0].FullName
    Assert-AtlasToggleDefinition -Definition $definition -ExpectedName $Name `
        -SourcePath $files[0].FullName
    return $definition
}

function Resolve-AtlasToggleReplayRecord {
    param(
        [Parameter(Mandatory = $true)]
        [ValidateNotNull()]
        $Subkey,

        [string]$TogglesRoot
    )

    $properties = Get-ItemProperty -LiteralPath $Subkey.PSPath -ErrorAction Stop
    if ($null -eq $properties -or
        -not $properties.PSObject.Properties['state'] -or
        $Subkey.GetValueKind('state') -ne [Microsoft.Win32.RegistryValueKind]::DWord) {
        throw (New-AtlasToggleStaleReplayRecordException -Message 'has no REG_DWORD state.')
    }
    $recordedState = [int]$properties.state

    $definition = Get-AtlasToggleReplayDefinition -Name ([string]$Subkey.PSChildName) `
        -TogglesRoot $TogglesRoot
    if ($definition.Contains('NoStateRecord') -and $definition.NoStateRecord) {
        throw (New-AtlasToggleStaleReplayRecordException `
                -Message 'belongs to a definition that no longer records state.')
    }

    $matchingStates = @($definition.States.Keys | Where-Object {
            $entry = $definition.States[$_]
            $entry.Contains('StateValue') -and [int]$entry.StateValue -eq $recordedState
        })
    if ($matchingStates.Count -ne 1) {
        throw (New-AtlasToggleStaleReplayRecordException `
                -Message "state '$recordedState' does not map to exactly one installed state.")
    }

    $stateName = [string]$matchingStates[0]
    $stateEntry = $definition.States[$stateName]
    if ($stateEntry.Contains('NoStateRecord') -and $stateEntry.NoStateRecord) {
        throw (New-AtlasToggleStaleReplayRecordException `
                -Message "state '$stateName' no longer records state.")
    }

    return [pscustomobject]@{
        Definition    = $definition
        RecordedState = $recordedState
        StateName     = $stateName
        StateEntry    = $stateEntry
    }
}

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

        try {
            $replay = Resolve-AtlasToggleReplayRecord -Subkey $subkey -TogglesRoot $TogglesRoot
        }
        catch {
            if ($_.Exception.Data['AtlasToggleReplayRecordDisposition'] -ceq 'Stale') {
                Remove-AtlasToggleReplayRecord `
                    -Name $name `
                    -KeyPath $subkey.PSPath `
                    -Reason $_.Exception.Message
            }
            else {
                $failureMessage = $_.Exception.Message
                Write-AtlasLog -Level Warning -Message `
                    "Resolving toggle '$name' for re-apply failed; preserving its record: $failureMessage" `
                    -ErrorRecord $_
                $failures += [pscustomobject]@{
                    Name    = $name
                    Message = [string]$failureMessage
                }
            }
            continue
        }

        Remove-AtlasToggleLegacyPath -KeyPath $subkey.PSPath

        $definition = $replay.Definition
        $stateName = $replay.StateName
        $stateEntry = $replay.StateEntry
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

        if ($stateEntry.Contains('ReplayApplicable')) {
            try {
                $isReplayApplicable = & $stateEntry.ReplayApplicable
            }
            catch {
                $failureMessage = $_.Exception.Message
                Write-AtlasLog -Level Warning -Message `
                    "Checking replay applicability for toggle '$name' failed; preserving its record: $failureMessage" `
                    -ErrorRecord $_
                $failures += [pscustomobject]@{
                    Name    = $name
                    Message = [string]$failureMessage
                }
                continue
            }
            if (-not $isReplayApplicable) {
                Remove-AtlasToggleReplayRecord `
                    -Name $name `
                    -KeyPath $subkey.PSPath `
                    -Reason "state '$stateName' is no longer applicable."
                continue
            }
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

function Invoke-AtlasToggleUserReapply {
    <#
    .SYNOPSIS
        Replays recorded split-toggle state for the current non-elevated user.
    #>
    param(
        [ValidateNotNullOrEmpty()]
        [string]$StateRoot = $script:AtlasToggleDefaultStateRoot,

        # Overridable for tests; defaults to the installed Toggles directory.
        [string]$TogglesRoot
    )

    if ((Test-AtlasSystem) -or (Test-AtlasAdmin)) {
        throw "Per-user toggle replay requires the affected user's non-elevated context."
    }
    if (-not (Test-Path -LiteralPath $StateRoot)) {
        Write-AtlasLog -Level Warning -Message "Registry path '$StateRoot' not found, skipping per-user replay."
        return
    }

    $failures = @()
    foreach ($subkey in @(Get-ChildItem -LiteralPath $StateRoot -ErrorAction Stop)) {
        $name = [string]$subkey.PSChildName

        try {
            $replay = Resolve-AtlasToggleReplayRecord -Subkey $subkey -TogglesRoot $TogglesRoot
        }
        catch {
            Write-AtlasLog -Level Warning -Message `
                "Skipping per-user replay for toggle '$name': $($_.Exception.Message)" -ErrorRecord $_
            continue
        }

        $definition = $replay.Definition
        $stateName = $replay.StateName
        $stateEntry = $replay.StateEntry
        if (-not (Test-AtlasToggleSplitMachineState -StateEntry $stateEntry)) {
            continue
        }

        Write-AtlasLog -Message "Re-applying toggle '$name' user state '$stateName'."
        try {
            Invoke-AtlasToggleInProcess `
                -Definition $definition `
                -StateName $stateName `
                -Silent `
                -NoExplorerRestart `
                -StateRoot $StateRoot `
                -UserContext `
                -ActionScope User
        }
        catch {
            $failureMessage = $_.Exception.Message
            Write-AtlasLog -Level Warning -Message `
                "Re-applying toggle '$name' user state failed: $failureMessage" -ErrorRecord $_
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
        throw "User toggle re-apply failed for $($failures.Count) toggle(s): $failureDetails"
    }
}
