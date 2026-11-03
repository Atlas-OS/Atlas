# Choices phase.
# Choosing again on an update (Upgrade or Reapply): applies each install choice where
# this PC differs from it, as a first installation would, and nothing else, so a resumed
# or repeated run redoes only what still differs. In order: Microsoft Defender,
# Microsoft Edge, the AppX families a choice removes, then the choice toggles
# (Choices.ps1). It records the toggles it set, which Defaults, running next, leaves out
# of its replay; the others are replayed as when keeping choices.
#
# Runs as TrustedInstaller. A servicing failure throws at once, as on a first
# installation, once Install-AtlasCbsPackage has armed the Safe Mode retry, and so does
# Edge's removal, as in Components. Toggle and AppX failures are collected, so every
# other choice is still applied, then thrown together.
#
# Not handled here: what an update never repeats (Atlas's other AppX removals, Phone
# Link, OneDrive, Smart App Control), and the Atlas toggles no install choice owns,
# whose records Defaults replays.

Assert-AtlasPrivilege -TrustedInstaller

$scriptsRoot = Split-Path -Parent (Split-Path -Parent $PSScriptRoot)
$modulesRoot = Join-Path -Path $scriptsRoot -ChildPath 'Modules'
foreach ($module in @('Atlas.Services', 'Atlas.TasksProcs', 'Atlas.Software', 'Atlas.Security', 'Atlas.Toggles', 'Atlas.Appx')) {
    Import-Module -Name (Join-Path $modulesRoot "$module\$module.psd1") -Force -ErrorAction Stop
}
. (Join-Path $scriptsRoot 'Preparation\WindowsTransition.ps1')
. (Join-Path $scriptsRoot 'Install\Tasks\Choices.ps1')
. (Join-Path $scriptsRoot 'Install\Tasks\Set-AtlasDefenderChoice.ps1')
. (Join-Path $scriptsRoot 'Install\Tasks\Invoke-AtlasEdgeRemoval.ps1')

$context = Get-AtlasContext
if (-not $context.IsChoosingAgain) {
    throw 'The Choices step runs only when an update chooses again.'
}
$options = @($context.Options | ForEach-Object { [string]$_ })
# What the PC has, read once before anything changes.
$facts = Get-AtlasTransitionMachineFact -UserSid ([string]$context.InteractiveUserSid)
$failures = [Collections.Generic.List[string]]::new()

# What earlier attempts of this installation did. A removal stays unfinished in the
# record until it ends, because once its apps are gone the PC no longer shows that
# the rest of it is still to do.
$record = Get-AtlasChoicesRecord
$applied = [Collections.Generic.List[string]]::new()
foreach ($name in $record.Applied) { $applied.Add($name) }
$unfinished = [Collections.Generic.List[string]]::new()
foreach ($work in $record.Unfinished) { $unfinished.Add($work) }
$saveRecord = { Save-AtlasChoicesRecord -Applied $applied.ToArray() -Unfinished $unfinished.ToArray() }

# Microsoft Defender, through Atlas's NoDefender package. Set-AtlasDefenderChoice
# changes only what differs, and warns about a choice it can't make.
$defender = @($options | Where-Object { $_ -ceq 'defender-enable' -or $_ -ceq 'defender-disable' })
if ($defender.Count -eq 1) {
    $state = if ($defender[0] -ceq 'defender-disable') { 'Disable' } else { 'Enable' }
    $package = [string]$facts.DefenderPackage
    # A package Windows adds or takes off at the restart already counts.
    $removed = $package -cin @('Installed', 'InstallPending')
    # With Defender already removed, Set-AtlasDefenderChoice still turns off a core
    # service an earlier Atlas left on, which it doesn't count as a Defender change.
    $coreServiceOn = $state -ceq 'Disable' -and $removed -and -not (Test-AtlasDefenderCoreServiceRemoved)
    # Only its last value is the result, whatever the commands under it write.
    if ($true -eq (Set-AtlasDefenderChoice -State $state | Select-Object -Last 1)) {
        $outcome = if ($state -ceq 'Disable') { 'Microsoft Defender is removed at the restart' } else { 'Microsoft Defender comes back at the restart' }
        Write-AtlasLog -Message "Applied choice '$($defender[0])': $outcome."
    }
    elseif ($coreServiceOn) {
        Write-AtlasLog -Message "Applied choice 'defender-disable': Atlas's NoDefender package already removes Microsoft Defender, and its core service is turned off at the next startup."
    }
    elseif (($state -ceq 'Disable' -and $removed) -or
        ($state -ceq 'Enable' -and ($package -ceq 'UninstallPending' -or (-not $package -and $true -eq $facts.Defender)))) {
        Write-AtlasLog -Message "Choice '$($defender[0])' already matches this PC."
    }
}

# Microsoft Edge and the AppX families a choice removes, removed as a first installation
# removes them: for the accounts of this PC that have them installed, as completion reads
# them, and for new accounts while Windows still provisions them, which a feature update
# would also bring back. One left only staged, or registered to SYSTEM or a removed
# account, is no removal to make on its own. An update can't put them back, so a cleared
# box changes nothing.
$installedFamilies = @($facts.Appx | Where-Object { $_ })
# Read only when a chosen family isn't installed for anyone, as it takes a while.
$provisioned = $null
$removals = [Collections.Generic.List[object]]::new()
foreach ($definition in @(Get-AtlasAppxRemovalDefinition)) {
    $option = [string]$definition.Option
    if (-not $option -or $options -cnotcontains $option) { continue }
    $pattern = [string]$definition.Name
    # Windows always has apps, so an empty list means they couldn't be listed; the
    # removal plan then reads them itself.
    $remove = $installedFamilies.Count -eq 0 -or @($installedFamilies | Where-Object { $_ -like $pattern }).Count -gt 0
    if (-not $remove) {
        if ($null -eq $provisioned) {
            $provisioned = [pscustomobject]@{ Read = $true; Families = @() }
            try { $provisioned.Families = @(Get-AtlasAppxProvisionedFamily) }
            catch {
                $provisioned.Read = $false
                Write-AtlasLog -Level Warning -Message "Couldn't list the apps Windows provisions for new accounts, so the app removal looks for the chosen ones itself: $($_.Exception.Message)"
            }
        }
        $remove = -not $provisioned.Read -or @($provisioned.Families | Where-Object { $_ -like $pattern }).Count -gt 0
    }
    if ($remove) {
        $removals.Add($definition)
    }
}
# An attempt stopped after msedge.exe went still owes the user's leftovers and Edge's
# deprovisioning, which come after it. Removing Edge where it is gone only clears its
# leftovers.
$removeEdge = $options -ccontains 'uninstall-edge' -and ($true -eq $facts.Edge -or $unfinished -ccontains 'Edge')
if ($removeEdge) {
    if ($unfinished -cnotcontains 'Edge') {
        $unfinished.Add('Edge')
        & $saveRecord
    }
    Invoke-AtlasEdgeRemoval -ScriptsRoot $scriptsRoot -Context $context
    [void]$unfinished.Remove('Edge')
    & $saveRecord
}

$appxFailed = $false
$finishAppx = $unfinished -ccontains 'Appx'
if ($removals.Count -gt 0 -or $finishAppx) {
    if ($finishAppx) {
        Write-AtlasLog -Message 'Finishing the app removal an interrupted attempt of this installation began.'
    }
    else {
        $unfinished.Add('Appx')
        & $saveRecord
    }
    # The snapshot lets the families the plan removes be deprovisioned, so a feature
    # update doesn't bring them back, and it keeps those an interrupted attempt's
    # snapshot listed. Without it nothing is removed.
    try {
        Save-AtlasAppxSnapshot
        if ($removals.Count -gt 0) {
            try {
                Invoke-AtlasAppxRemovalPlan -Definition $removals.ToArray()
            }
            catch {
                $appxFailed = $true
                $failures.Add("AppX removal: $($_.Exception.Message)")
            }
        }
        try {
            Set-AtlasAppxDeprovisioned
        }
        catch {
            $appxFailed = $true
            $message = "Deprovisioning removed AppX packages failed: $($_.Exception.Message)"
            $failures.Add($message)
            Write-AtlasLog -Level Error -Message $message
        }
    }
    catch {
        $appxFailed = $true
        $message = "The AppX snapshot failed, so no app was removed: $($_.Exception.Message)"
        $failures.Add($message)
        Write-AtlasLog -Level Error -Message $message
    }
    if (-not $appxFailed) {
        [void]$unfinished.Remove('Appx')
        & $saveRecord
    }
}
$planned = @($removals | ForEach-Object { [string]$_.Option })
foreach ($option in @('uninstall-edge', 'remove-snipping-tool')) {
    if ($options -cnotcontains $option) { continue }
    $appsPlanned = $planned -ccontains $option
    $outcome = if ($option -ceq 'uninstall-edge' -and $removeEdge) { 'Microsoft Edge removed' }
    elseif (-not $appsPlanned) { $null }
    elseif ($option -ceq 'uninstall-edge') { "Microsoft Edge's remaining apps removed" }
    else { 'Snipping Tool removed for every account' }
    if (-not $outcome) { Write-AtlasLog -Message "Choice '$option' already matches this PC." }
    elseif (-not ($appsPlanned -and $appxFailed)) { Write-AtlasLog -Message "Applied choice '$option': $outcome." }
}

# The choice toggles. Each state is applied and recorded only after its machine work
# succeeds, as Defaults would replay it.
$records = @{}
foreach ($toggleRecord in @($facts.Toggles | Where-Object { $null -ne $_ })) {
    $records[[string]$toggleRecord.name] = [int64]$toggleRecord.state
}
$appliedBefore = $applied.Count
$targets = @(Get-AtlasChoiceToggleTarget -Options $options -Records $records -CoreIsolationOff $facts.CoreIsolationOff)
foreach ($target in $targets) {
    $label = if ($target.Chosen) { "'$($target.Option)'" } else { "'$($target.Option)' left out" }
    if ($target.Matches) {
        $note = if ($target.Note) { "; $($target.Note)" } else { '' }
        Write-AtlasLog -Message "Choice ${label}: $($target.Name) is already recorded as $($target.State)$note."
        continue
    }
    if ($target.Name -ceq 'VbsState') {
        # The toggle fails on a change that policy or a UEFI lock refuses, so the change
        # is checked first. VBS then stays as it is, unrecorded, and completion records
        # what the PC has.
        $reason = Test-AtlasVbsChange -State $target.State
        if ($reason) {
            Write-AtlasLog -Level Warning -Message "Left VBS as it is: $reason."
            continue
        }
    }
    try {
        Invoke-AtlasToggleMachineState -Name $target.Name -State $target.State
        if ($applied -cnotcontains $target.Name) { $applied.Add($target.Name) }
        Write-AtlasLog -Message "Applied choice ${label}: $($target.Name) set to $($target.State)."
    }
    catch {
        $message = "Applying choice $label ($($target.Name) $($target.State)) failed: $($_.Exception.Message)"
        $failures.Add($message)
        Write-AtlasLog -Level Warning -Message $message -ErrorRecord $_
    }
}
# Saved before any failure is thrown, so the attempt that gets past this step still
# leaves out of the replay what this one set.
if ($applied.Count -ne $appliedBefore) {
    & $saveRecord
}

if ($failures.Count -gt 0) {
    throw "The Choices phase failed for $($failures.Count) choice(s): $($failures -join ' | ')"
}
