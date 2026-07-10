# Atlas.Toggles domain: upgrade re-apply.
#
# On upgrades, every known toggle recorded under HKLM\SOFTWARE\AtlasOS\Services with
# state != 0 is resolved from the protected installed definitions and re-applied through
# the PowerShell toggle engine. Registry data is declarative and is never executed.

function Invoke-AtlasToggleReapply {
    <#
    .SYNOPSIS
        Re-applies every valid recorded toggle whose state is not 0. Unknown, malformed,
        and NoStateRecord entries are removed; legacy executable-path values are scrubbed.
    #>
    param(
        [ValidateNotNullOrEmpty()]
        [string]$StateRoot = $script:AtlasToggleDefaultStateRoot,

        # Overridable for tests; defaults to the installed Toggles directory.
        [string]$TogglesRoot
    )

    if (-not (Test-Path -LiteralPath $StateRoot)) {
        Write-AtlasLog -Level Warning -Message "Registry path '$StateRoot' not found, skipping."
        return
    }

    # Close the write boundary before inspecting any record. IncludeChildren migrates
    # existing installs whose child keys inherited or retained a user-writable ACL.
    Protect-AtlasToggleStateRoot -StateRoot $StateRoot -IncludeChildren

    foreach ($subkey in @(Get-ChildItem -LiteralPath $StateRoot)) {
        $properties = Get-ItemProperty -LiteralPath $subkey.PSPath -ErrorAction SilentlyContinue
        if ($null -eq $properties -or -not $properties.PSObject.Properties['state']) {
            Write-AtlasLog -Level Warning -Message "Toggle '$($subkey.PSChildName)' has no declarative state, removing invalid registry key."
            Remove-Item -LiteralPath $subkey.PSPath -Force -Recurse -ErrorAction Stop
            continue
        }

        $definition = $null
        try {
            $definitionArgs = @{ Name = $subkey.PSChildName }
            if ($TogglesRoot) {
                $definitionArgs['TogglesRoot'] = $TogglesRoot
            }
            $definition = Get-AtlasToggleDefinition @definitionArgs
        }
        catch {
            Write-AtlasLog -Level Warning -Message "Toggle '$($subkey.PSChildName)' has no valid installed definition, removing untrusted registry record."
            Remove-Item -LiteralPath $subkey.PSPath -Force -Recurse -ErrorAction Stop
            continue
        }

        # A record whose current definition is NoStateRecord is stale by definition
        # (e.g. a SafeMode state written by an older Atlas). Re-applying it is exactly
        # the hazard the flag exists to prevent, so clean it up instead of replaying it.
        if ($definition -and $definition.Contains('NoStateRecord') -and $definition.NoStateRecord) {
            Write-AtlasLog -Level Warning -Message "Toggle '$($subkey.PSChildName)' does not record state, cleaning up stale registry key."
            Remove-Item -LiteralPath $subkey.PSPath -Force -Recurse -ErrorAction Stop
            continue
        }

        if ($subkey.GetValueKind('state') -ne [Microsoft.Win32.RegistryValueKind]::DWord) {
            Write-AtlasLog -Level Warning -Message "Toggle '$($subkey.PSChildName)' state is not REG_DWORD, removing invalid registry key."
            Remove-Item -LiteralPath $subkey.PSPath -Force -Recurse -ErrorAction Stop
            continue
        }

        $recordedState = $null
        try {
            $recordedState = [int]$properties.state
        }
        catch {
            Write-AtlasLog -Level Warning -Message "Toggle '$($subkey.PSChildName)' has a non-numeric state, removing invalid registry key."
            Remove-Item -LiteralPath $subkey.PSPath -Force -Recurse -ErrorAction Stop
            continue
        }

        $matchingStates = @()
        foreach ($stateName in @($definition.States.Keys)) {
            $stateEntry = $definition.States[$stateName]
            if ($stateEntry.Contains('StateValue') -and [int]$stateEntry.StateValue -eq $recordedState) {
                $matchingStates += [string]$stateName
            }
        }

        if ($matchingStates.Count -ne 1) {
            Write-AtlasLog -Level Warning -Message "Toggle '$($subkey.PSChildName)' state '$recordedState' does not map to exactly one installed state, removing invalid registry key."
            Remove-Item -LiteralPath $subkey.PSPath -Force -Recurse -ErrorAction Stop
            continue
        }

        $matchingState = $definition.States[$matchingStates[0]]
        if ($matchingState.Contains('NoStateRecord') -and $matchingState.NoStateRecord) {
            Write-AtlasLog -Level Warning -Message "Toggle '$($subkey.PSChildName)' state '$($matchingStates[0])' does not record state, cleaning up stale registry key."
            Remove-Item -LiteralPath $subkey.PSPath -Force -Recurse -ErrorAction Stop
            continue
        }

        # Remove the legacy executable path before the replay action starts. Even a
        # failing action cannot leave an execution sink.
        Remove-AtlasToggleLegacyPath -KeyPath $subkey.PSPath

        if ($recordedState -ne 0) {
            Write-AtlasLog -Message "Re-applying toggle '$($subkey.PSChildName)' state '$($matchingStates[0])' from its installed definition."
            try {
                $invokeArgs = @{
                    Name        = [string]$definition.Name
                    State       = $matchingStates[0]
                    Silent      = $true
                    StateRoot   = $StateRoot
                }
                if ($TogglesRoot) {
                    $invokeArgs['TogglesRoot'] = $TogglesRoot
                }
                Invoke-AtlasToggle @invokeArgs
            }
            catch {
                Write-AtlasLog -Level Warning -Message "Re-applying toggle '$($subkey.PSChildName)' failed: $($_.Exception.Message)" -ErrorRecord $_
            }
        }
    }
}
