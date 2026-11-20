# The install choices a Choose again update applies through Atlas's own toggles, as pure
# rules. Get-AtlasChoiceToggleTarget gives the state each choice sets, from the options
# chosen and what Atlas recorded. The Choices phase applies the states the PC doesn't
# have yet and records which toggles it set (Get-AtlasChoicesRecord). Defaults leaves
# those out of its replay on that update, as they were just applied, and replays the
# rest as when keeping choices.

function Get-AtlasChoiceToggleName {
    <#
    .SYNOPSIS
        The toggles the install choices own, in the order the Choices phase applies them.
    #>
    # PowerSaving switches the active power plan, which drops per-plan settings, so it
    # goes first, as it does in replay.
    return @('PowerSaving', 'Hibernation', 'Mitigations', 'AutomaticUpdates', 'VbsState', 'KeyboardShortcuts')
}

function Get-AtlasChoiceToggleTarget {
    <#
    .SYNOPSIS
        The state each choice toggle is set to when an update chooses again, in the order
        of Get-AtlasChoiceToggleName, as { Name; State; Option; Chosen; Matches; Note }.
    .DESCRIPTION
        Option is the install option the state comes from. Chosen is $false for a box
        left clear. Matches says Atlas's record already has the state, and for VBS that
        the DeviceGuard values agree, so the Choices phase leaves it to the replay.

        A ticked box or a disable answer gives Disable. A cleared box or a default answer
        undoes Atlas's own Disable: it gives Enable, or WindowsDefault for processor
        protections, when Atlas has recorded the toggle. Without a record it gives
        nothing, so a power plan or update setting the user made is never touched.
        Processor protections all on (a record of 2) stay all on with the default answer.
        The keyboard answer always gives its state, so it is recorded. VBS is judged by
        the DeviceGuard values as well as the record: clearing "Turn off VBS" turns VBS
        back on when it is off.

        Like the other option lists, one target comes back on its own, so callers wrap
        the result in @().
    #>
    [CmdletBinding()]
    [OutputType([pscustomobject])]
    param(
        [AllowEmptyCollection()]
        [string[]]$Options = @(),

        # Recorded toggle states by name, as Get-AtlasToggleStateRecords gives them.
        [AllowNull()]
        [Collections.IDictionary]$Records = @{},

        # Whether the DeviceGuard values show VBS off; $null when they weren't read.
        [Nullable[bool]]$CoreIsolationOff
    )

    # The StateValue of each state these rules give, as the definitions declare them.
    $values = @{
        PowerSaving       = @{ Disable = 0; Enable = 1 }
        Hibernation       = @{ Disable = 0; Enable = 1 }
        Mitigations       = @{ Disable = 0; WindowsDefault = 1; Enable = 2 }
        AutomaticUpdates  = @{ Disable = 0; Enable = 1 }
        VbsState          = @{ Disable = 0; Enable = 1 }
        KeyboardShortcuts = @{ Disable = 0; Enable = 1 }
    }
    $chosen = @($Options | ForEach-Object { [string]$_ })
    $recorded = @{}
    foreach ($name in @($values.Keys)) {
        if ($null -ne $Records -and $Records.Contains($name) -and $null -ne $Records[$name]) {
            $recorded[$name] = [int64]$Records[$name]
        }
    }
    # Atlas's own two states of an on/off choice toggle.
    $isRecorded = { param([string]$Name) $recorded.ContainsKey($Name) -and $recorded[$Name] -in @(0, 1) }

    $targets = [Collections.Generic.List[object]]::new()
    $add = {
        param([string]$Name, [string]$State, [string]$Option, [bool]$Chosen, [string]$Note)
        $current = $recorded.ContainsKey($Name) -and $recorded[$Name] -eq $values[$Name][$State]
        # A VBS record can outlast the change it made: Windows Security and other
        # tools change the same values.
        if ($Name -ceq 'VbsState' -and $null -ne $CoreIsolationOff) {
            $current = $current -and $CoreIsolationOff -eq ($State -ceq 'Disable')
        }
        $targets.Add([pscustomobject][ordered]@{
                Name = $Name; State = $State; Option = $Option; Chosen = $Chosen
                Matches = [bool]$current; Note = $Note
            })
    }

    $checkboxes = [ordered]@{ PowerSaving = 'disable-power-saving'; Hibernation = 'disable-hibernation' }
    foreach ($name in @($checkboxes.Keys)) {
        $option = $checkboxes[$name]
        if ($chosen -ccontains $option) { & $add $name 'Disable' $option $true }
        elseif (& $isRecorded $name) { & $add $name 'Enable' $option $false }
    }

    if ($chosen -ccontains 'mitigations-disable') { & $add 'Mitigations' 'Disable' 'mitigations-disable' $true }
    elseif ($chosen -ccontains 'mitigations-default' -and $recorded.ContainsKey('Mitigations')) {
        if ($recorded['Mitigations'] -eq 2) {
            & $add 'Mitigations' 'Enable' 'mitigations-default' $true `
                'all processor protections are turned on, and keeping protections leaves them all on'
        }
        elseif ($recorded['Mitigations'] -in @(0, 1)) { & $add 'Mitigations' 'WindowsDefault' 'mitigations-default' $true }
    }

    if ($chosen -ccontains 'auto-updates-disable') { & $add 'AutomaticUpdates' 'Disable' 'auto-updates-disable' $true }
    elseif ($chosen -ccontains 'auto-updates-default' -and (& $isRecorded 'AutomaticUpdates')) {
        & $add 'AutomaticUpdates' 'Enable' 'auto-updates-default' $true
    }

    if ($chosen -ccontains 'disable-core-isolation') { & $add 'VbsState' 'Disable' 'disable-core-isolation' $true }
    elseif ((& $isRecorded 'VbsState') -or $true -eq $CoreIsolationOff) {
        & $add 'VbsState' 'Enable' 'disable-core-isolation' $false
    }

    foreach ($keyboard in @('keyboard-shortcuts', 'keyboard-selector', 'keyboard-single')) {
        if ($chosen -ccontains $keyboard) {
            # The language selector and the single layout share Disable; the option
            # records which of the two it was.
            & $add 'KeyboardShortcuts' $(if ($keyboard -ceq 'keyboard-shortcuts') { 'Enable' } else { 'Disable' }) $keyboard $true
            break
        }
    }

    return $targets.ToArray()
}

function Get-AtlasChoicesRecordPath {
    <#
    .SYNOPSIS
        Where the Choices step records what it has done in this installation.
    #>
    # With the installation's own work, which file replacement leaves alone and only
    # completion removes, so a resumed Choices step and the Defaults step after it read
    # what every attempt of this installation did.
    return Join-Path -Path ([string](Get-AtlasContext).WinDir) -ChildPath 'AtlasOS\Install\work\choices.json'
}

function Get-AtlasChoicesRecord {
    <#
    .SYNOPSIS
        What the Choices step has done in this installation, as { Applied; Unfinished }:
        the choice toggles it set, and the removals it began without finishing ('Edge',
        'Appx'), so the next attempt finishes them.
    .DESCRIPTION
        Without a record, with one another installation left, or with one that can't be
        read (a warning), there is neither. That is safe: Defaults then replays every
        record, and each holds the state the Choices step applied or already matched.
    #>
    [CmdletBinding()]
    [OutputType([pscustomobject])]
    param(
        [ValidateNotNullOrEmpty()]
        [string]$Path = (Get-AtlasChoicesRecordPath),

        [string]$TransactionId = [string](Get-AtlasContext).TransactionId
    )

    $record = [pscustomobject]@{ Applied = [string[]]@(); Unfinished = [string[]]@() }
    if (-not [IO.File]::Exists($Path)) {
        return $record
    }
    try {
        $document = [IO.File]::ReadAllText($Path) | ConvertFrom-Json -ErrorAction Stop
        if ($null -eq $document) { throw 'it is empty.' }
        foreach ($field in @('transactionId', 'applied', 'unfinished')) {
            if ($null -eq $document.PSObject.Properties[$field]) { throw "it has no '$field'." }
        }
        # Only completion clears the work, so an installation that never completed can
        # leave its record behind; what it did says nothing about this one.
        if ([string]$document.transactionId -cne $TransactionId) {
            Write-AtlasLog -Message "Ignoring the Choices step's record '$Path', which another installation left."
            return $record
        }
        $applied = @($document.applied)
        $unfinished = @($document.unfinished)
        $toggles = @(Get-AtlasChoiceToggleName)
        foreach ($name in $applied) {
            if ($name -isnot [string] -or $toggles -cnotcontains $name) { throw "'$name' isn't a choice toggle." }
        }
        foreach ($work in $unfinished) {
            if ($work -isnot [string] -or $work -cnotin @('Edge', 'Appx')) { throw "'$work' isn't a removal the Choices step makes." }
        }
        $record.Applied = [string[]]$applied
        $record.Unfinished = [string[]]$unfinished
    }
    catch {
        Write-AtlasLog -Level Warning -Message "Ignoring the Choices step's record '$Path', which can't be read: $($_.Exception.Message)"
    }
    return $record
}

function Save-AtlasChoicesRecord {
    <#
    .SYNOPSIS
        Replaces the Choices step's record of this installation (Get-AtlasChoicesRecord).
    #>
    [CmdletBinding()]
    param(
        [AllowEmptyCollection()]
        [string[]]$Applied = @(),

        [AllowEmptyCollection()]
        [string[]]$Unfinished = @(),

        [ValidateNotNullOrEmpty()]
        [string]$Path = (Get-AtlasChoicesRecordPath),

        [ValidateNotNullOrEmpty()]
        [string]$TransactionId = [string](Get-AtlasContext).TransactionId
    )

    $directory = [IO.Path]::GetDirectoryName($Path)
    if (-not [IO.Directory]::Exists($directory)) {
        [void][IO.Directory]::CreateDirectory($directory)
    }
    $json = [pscustomobject][ordered]@{
        transactionId = $TransactionId
        applied       = @($Applied | Sort-Object -Unique)
        unfinished    = @($Unfinished | Sort-Object -Unique)
    } | ConvertTo-Json -Compress
    # Written whole, then swapped in, so a stopped write never leaves half a record.
    $temporary = "$Path.tmp"
    [IO.File]::WriteAllText($temporary, $json, [Text.UTF8Encoding]::new($false))
    if ([IO.File]::Exists($Path)) { [IO.File]::Replace($temporary, $Path, [NullString]::Value) }
    else { [IO.File]::Move($temporary, $Path) }
}
