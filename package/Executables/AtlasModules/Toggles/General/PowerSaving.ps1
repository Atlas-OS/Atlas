# Companion for the PowerSaving toggle: applies the Atlas power settings or restores the
# earlier power plan, and sets device power saving to match. Invoke-AtlasPowerSavingToggle
# runs as Administrator when you run a launcher, when the install applies your power-saving
# choice and when an update replays the recorded state.

function Invoke-AtlasPowerSavingToggle {
    param($Toggle)

    switch -CaseSensitive ([string]$Toggle.State) {
        'Disable' {
            $mode = 'Atlas'
            $message = "The Atlas AC power policy is active, and Windows can't turn off devices to save power."
        }
        'Enable' {
            $mode = 'Default'
            $message = 'The previous power plan, or Balanced when none was saved, is active, the Atlas plan was removed and Windows can turn off devices to save power again.'
        }
        default { throw "PowerSaving: unsupported state '$($Toggle.State)'." }
    }

    Import-AtlasModule -Name Atlas.Hardware
    Set-AtlasPowerSavingState -Mode $mode -Silent:$Toggle.Silent

    # Power saving off clears "Allow the computer to turn off this device to save power" on
    # every device that offers it, and power saving on ticks it on every device. A device
    # that appears later keeps its driver's default until the toggle runs again.
    $devicePowerSaving = if ($mode -ceq 'Atlas') { 'Off' } else { 'On' }
    try {
        [void](Set-AtlasDevicePowerSaving -State $devicePowerSaving)
    }
    catch {
        Write-AtlasLog -Level Warning -NoConsole:(-not $Toggle.Silent) -ErrorRecord $_ -Message `
            "PowerSaving couldn't turn device power saving $($devicePowerSaving.ToLowerInvariant()): $($_.Exception.Message)"
        if (-not $Toggle.Silent) {
            Write-AtlasPartial -Text "The power plan changed, but Windows couldn't list the devices' power-saving settings. Run this launcher again."
        }
    }

    # CPU idle and sleep settings belong to a plan, and both modes leave a different
    # plan active, so the recorded choices are applied to it again. The plan change
    # stands even when a record can't be read or applied.
    $planFolders = @{ CpuIdle = 'CPU Idle'; Sleep = 'Sleep' }
    foreach ($planToggle in @('CpuIdle', 'Sleep')) {
        try {
            $record = Get-AtlasToggleState -Name $planToggle -StateRoot $Toggle.StateRoot
            if ($null -eq $record -or $record.State -notin @(0, 1)) {
                continue
            }
            $planState = @('Disable', 'Enable')[[int]$record.State]
            # Upgrade replay skips a choice this PC can't take, such as disabling CPU
            # idle with SMT on, so it isn't a failure here either.
            $planDefinition = Get-AtlasToggleDefinition -Name $planToggle
            if (-not (Test-AtlasToggleReplayApplicable -Definition $planDefinition -StateName $planState `
                        -StateRoot $Toggle.StateRoot)) {
                Write-AtlasLog -Message "PowerSaving left the recorded $planToggle choice: it doesn't apply on this PC."
                continue
            }
            Invoke-AtlasToggleMachineState -Name $planToggle -State $planState -StateRoot $Toggle.StateRoot
        }
        catch {
            Write-AtlasLog -Level Warning -NoConsole:(-not $Toggle.Silent) -ErrorRecord $_ -Message `
                "PowerSaving couldn't apply the recorded $planToggle choice to the new power plan: $($_.Exception.Message)"
            if (-not $Toggle.Silent) {
                $planFolder = $planFolders[$planToggle]
                Write-AtlasPartial -Text "The power plan changed, but your $planFolder choice couldn't be applied to it. Run its launcher in the $planFolder folder again."
            }
        }
    }

    if (-not $Toggle.Silent) {
        Write-AtlasSuccess -Text $message
    }
}
