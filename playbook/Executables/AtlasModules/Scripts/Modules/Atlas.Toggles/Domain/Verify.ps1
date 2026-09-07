# Atlas.Toggles domain: verification of recorded toggle states.
#
# A toggle's declarative work can be read back as well as applied. Test-AtlasToggleState
# reports every Registry, Services or ScheduledTasks declaration of one state that no
# longer holds on this machine; Test-AtlasToggleDrift does that for every recorded
# state. Companion functions are imperative and are not verified here.

function Test-AtlasToggleState {
    <#
    .SYNOPSIS
        Returns the drift of one toggle state's declarative work for one scope.
    .OUTPUTS
        One object per drifted declaration: Toggle, State, Scope, Kind, Target, Reason.
    #>
    param(
        [Parameter(Mandatory = $true)]
        [System.Collections.IDictionary]$Definition,

        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [string]$StateName,

        [Parameter(Mandatory = $true)]
        [ValidateSet('Machine', 'User')]
        [string]$Scope
    )

    if (-not $Definition['States'].Contains($StateName)) {
        throw "Toggle '$($Definition['Name'])' does not define state '$StateName'."
    }
    $stateEntry = $Definition['States'][$StateName]
    $toggleName = [string]$Definition['Name']
    $drift = @()

    if (Test-AtlasToggleStateHasKey -StateEntry $stateEntry -Key 'Registry') {
        $registryScope = if ($Scope -ceq 'Machine') { 'Machine' } else { 'CurrentUser' }
        foreach ($item in @(Test-AtlasRegistryEntries -Entries @($stateEntry['Registry'] | ForEach-Object { [hashtable]$_ }) -Scope $registryScope)) {
            $drift += [pscustomobject]@{
                Toggle = $toggleName; State = $StateName; Scope = $Scope; Kind = 'Registry'
                Target = "$($item.Path)\$($item.Name)"; Reason = $item.Reason
            }
        }
    }

    if ($Scope -ceq 'Machine') {
        if (Test-AtlasToggleStateHasKey -StateEntry $stateEntry -Key 'Services') {
            foreach ($item in @(Test-AtlasServiceEntries -Entries @($stateEntry['Services'] | ForEach-Object { [hashtable]$_ }))) {
                $drift += [pscustomobject]@{
                    Toggle = $toggleName; State = $StateName; Scope = $Scope; Kind = 'Service'
                    Target = $item.Service; Reason = "$($item.Reason) (expected $($item.Expected), found $($item.Actual))"
                }
            }
        }
        if (Test-AtlasToggleStateHasKey -StateEntry $stateEntry -Key 'ScheduledTasks') {
            foreach ($item in @(Test-AtlasScheduledTaskEntries -Entries @($stateEntry['ScheduledTasks'] | ForEach-Object { [hashtable]$_ }))) {
                $drift += [pscustomobject]@{
                    Toggle = $toggleName; State = $StateName; Scope = $Scope; Kind = 'ScheduledTask'
                    Target = $item.Task; Reason = "$($item.Reason) (expected $($item.Expected), found $($item.Actual))"
                }
            }
        }
    }

    return $drift
}

function Test-AtlasToggleDrift {
    <#
    .SYNOPSIS
        Verifies every recorded toggle state against the installed definitions and
        returns the drift. Machine scope needs no particular identity to read; User
        scope reads the calling account's own hive and is meaningful only from that
        user's session.
    #>
    param(
        [ValidateSet('Machine', 'User')]
        [string[]]$Scope = @('Machine'),

        [ValidateNotNullOrEmpty()]
        [string]$StateRoot = $script:AtlasToggleDefaultStateRoot,

        [string]$TogglesRoot
    )

    $drift = @()
    $records = Get-AtlasToggleStateRecords -StateRoot $StateRoot
    foreach ($name in @($records.Keys | Sort-Object)) {
        $recordedValue = [int]$records[$name]
        try {
            $definition = Get-AtlasToggleDefinition -Name $name -TogglesRoot $TogglesRoot
        }
        catch {
            $drift += [pscustomobject]@{
                Toggle = $name; State = [string]$recordedValue; Scope = 'Machine'; Kind = 'Definition'
                Target = $name; Reason = "recorded state has no loadable definition: $($_.Exception.Message)"
            }
            continue
        }
        $stateName = @($definition['States'].Keys | Where-Object {
                $entry = $definition['States'][$_]
                $entry.Contains('StateValue') -and [int]$entry['StateValue'] -eq $recordedValue
            }) | Select-Object -First 1
        if ($null -eq $stateName) {
            $drift += [pscustomobject]@{
                Toggle = $name; State = [string]$recordedValue; Scope = 'Machine'; Kind = 'Definition'
                Target = $name; Reason = "recorded value $recordedValue matches no installed state"
            }
            continue
        }
        foreach ($oneScope in $Scope) {
            $drift += @(Test-AtlasToggleState -Definition $definition -StateName ([string]$stateName) -Scope $oneScope)
        }
    }
    return $drift
}
