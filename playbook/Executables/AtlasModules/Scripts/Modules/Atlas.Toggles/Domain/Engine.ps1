# Atlas.Toggles domain: definition loading and the toggle engine.
#
# A toggle definition is a .ps1 under AtlasModules\Toggles\<Group>\<SettingName>.ps1 that
# returns a hashtable:
#
#   @{
#       Name      = 'SuperFetch'          # registry key name under AtlasOS\Services
#       Elevation = 'Admin'               # 'Admin' | 'TrustedInstaller' | 'None'
#       Warning   = '...'                 # optional, shown + confirmed interactively
#       Menu      = $false                # $true for single-launcher multi-state pickers
#       Launcher  = '...'                 # Menu toggles: AtlasDesktop-relative launcher
#       ToolboxLauncher = '...'           # optional, Toolbox-relative launcher consumed by
#                                         # the launcher generator (tools\dev)
#       SilentDefault = 'Enable'          # Menu toggles: state used with /silent and no
#                                         # recorded state to re-apply
#       NoStateRecord = $true             # optional, skip the state registry entirely
#       States    = [ordered]@{
#           Disable = @{
#               StateValue = 0            # REG_DWORD written to the state registry
#               Launcher   = '...'        # AtlasDesktop-relative launcher path
#               Reboot     = 'Recommend'  # 'Recommend' | 'Prompt' | 'None' | 'RestartExplorer'
#               MenuLabel  = '...'        # optional, label used by Show-AtlasStateMenu
#               Action     = { param($Toggle) ... }
#               # Privileged states that combine machine and per-user work use the
#               # exact split below instead of Action. StateValue then records only
#               # the completed MachineAction; UserAction is re-applied per profile.
#               StateRecordScope = 'Machine'
#               MachineAction = { param($Toggle) ... }
#               UserAction    = { param($Toggle) ... }
#               # Legacy machine-only states must opt in before strict-TI
#               # upgrade replay may execute their Action.
#               ReplayScope = 'Machine'
#               ReplayApplicable = { ... } # optional, false removes a stale machine
#                                          # replay record without running Action
#               ContextAction = { ... }   # optional, runs before Action; -JustContext
#                                         # stops after it
#               NoStateRecord = $true     # optional, per-state variant
#           }
#       }
#   }
#
# The launcher never elevates - the engine does. Action blocks run non-strict for
# compatibility with legacy definitions, but ordinary PowerShell errors are terminating
# so a failed action can never be recorded as successfully applied.

$script:AtlasServiceDefaultResetStates = [ordered]@{
    Bluetooth                        = 'Enable'
    LanmanWorkstation                = 'Enable'
    NetworkDiscovery                 = 'Enable'
    NVidiaDisplayContainer           = 'Enable'
    NVidiaDisplayContainerContextMenu = 'Remove'
    Printing                         = 'Enable'
    SuperFetch                       = 'Enable'
}

function Get-AtlasToggleRoot {
    param(
        [string]$TogglesRoot
    )

    if ($TogglesRoot) {
        return $TogglesRoot
    }

    return Join-Path -Path (Get-AtlasContext).AtlasModulesPath -ChildPath 'Toggles'
}

function Test-AtlasToggleSplitMachineState {
    param(
        [Parameter(Mandatory = $true)]
        [System.Collections.IDictionary]$StateEntry
    )

    return $StateEntry.Contains('MachineAction') -and
        $StateEntry.MachineAction -is [scriptblock] -and
        $StateEntry.Contains('UserAction') -and
        $StateEntry.UserAction -is [scriptblock] -and
        $StateEntry.Contains('StateRecordScope') -and
        [string]$StateEntry.StateRecordScope -ceq 'Machine'
}

function Assert-AtlasToggleDefinition {
    <#
    .SYNOPSIS
        Validates the shape of a loaded toggle definition; throws with a descriptive
        message on the first problem found.
    #>
    param(
        $Definition,

        [Parameter(Mandatory = $true)]
        [string]$ExpectedName,

        [Parameter(Mandatory = $true)]
        [string]$SourcePath
    )

    if ($Definition -isnot [System.Collections.IDictionary]) {
        throw "Toggle definition '$SourcePath' did not return a hashtable."
    }

    $allowedTopLevelKeys = @(
        'Name', 'Elevation', 'Warning', 'Menu', 'Launcher', 'ToolboxLauncher',
        'SilentDefault', 'NoStateRecord', 'States'
    )
    foreach ($topLevelKey in @($Definition.Keys)) {
        if ($allowedTopLevelKeys -cnotcontains [string]$topLevelKey) {
            throw "Toggle definition '$SourcePath' has an unknown top-level key '$topLevelKey'. Valid keys: $($allowedTopLevelKeys -join ', ')."
        }
    }

    if (-not $Definition.Contains('Name') -or [string]::IsNullOrWhiteSpace([string]$Definition.Name)) {
        throw "Toggle definition '$SourcePath' is missing the required 'Name' key."
    }

    if ([string]$Definition.Name -cne $ExpectedName) {
        throw "Toggle definition '$SourcePath' declares Name '$($Definition.Name)' but its file name requires '$ExpectedName'."
    }

    if ($Definition.Contains('Elevation') -and $Definition.Elevation -and
        @('Admin', 'TrustedInstaller', 'None') -cnotcontains [string]$Definition.Elevation) {
        throw "Toggle definition '$SourcePath' has an invalid Elevation '$($Definition.Elevation)'. Valid values: Admin, TrustedInstaller, None."
    }

    # States must be [ordered] so menu numbering and replay resolution are deterministic.
    if (-not $Definition.Contains('States') -or
        $Definition.States -isnot [System.Collections.Specialized.OrderedDictionary] -or
        $Definition.States.Count -eq 0) {
        throw "Toggle definition '$SourcePath' is missing a non-empty '[ordered]' 'States' dictionary."
    }

    $elevation = if ($Definition.Contains('Elevation') -and $Definition.Elevation) {
        [string]$Definition.Elevation
    }
    else {
        'None'
    }
    $definitionNoRecord = $Definition.Contains('NoStateRecord') -and $Definition.NoStateRecord

    foreach ($stateName in @($Definition.States.Keys)) {
        $stateEntry = $Definition.States[$stateName]
        if ($stateEntry -isnot [System.Collections.IDictionary]) {
            throw "Toggle definition '$SourcePath' state '$stateName' is not a hashtable."
        }

        $hasAction = $stateEntry.Contains('Action')
        $hasSplitKeys = $stateEntry.Contains('MachineAction') -or
            $stateEntry.Contains('UserAction') -or
            $stateEntry.Contains('StateRecordScope')
        $isSplit = Test-AtlasToggleSplitMachineState -StateEntry $stateEntry

        if (($hasAction -and $hasSplitKeys) -or (-not $hasAction -and -not $hasSplitKeys)) {
            throw "Toggle definition '$SourcePath' state '$stateName' is missing an Action or exact MachineAction/UserAction split."
        }
        if ($hasAction -and $stateEntry.Action -isnot [scriptblock]) {
            throw "Toggle definition '$SourcePath' state '$stateName' has an invalid Action."
        }
        if ($hasSplitKeys -and (-not $isSplit -or $elevation -notin @('Admin', 'TrustedInstaller'))) {
            throw "Toggle definition '$SourcePath' state '$stateName' has an invalid privileged MachineAction/UserAction split."
        }
        if ($isSplit -and ($stateEntry.Contains('ContextAction') -or $stateEntry.Contains('ReplayScope'))) {
            throw "Toggle definition '$SourcePath' state '$stateName' cannot combine its privileged split with ContextAction or ReplayScope."
        }
        if ($stateEntry.Contains('ReplayScope') -and
            (-not $hasAction -or [string]$stateEntry.ReplayScope -cne 'Machine' -or
                $elevation -notin @('Admin', 'TrustedInstaller'))) {
            throw "Toggle definition '$SourcePath' state '$stateName' has an invalid machine replay classification."
        }
        if ($stateEntry.Contains('ReplayApplicable') -and
            ($stateEntry.ReplayApplicable -isnot [scriptblock] -or
                -not $stateEntry.Contains('ReplayScope') -or
                [string]$stateEntry.ReplayScope -cne 'Machine')) {
            throw "Toggle definition '$SourcePath' state '$stateName' has an invalid ReplayApplicable predicate."
        }

        $stateNoRecord = $stateEntry.Contains('NoStateRecord') -and $stateEntry.NoStateRecord
        if (-not $definitionNoRecord -and -not $stateNoRecord -and -not $stateEntry.Contains('StateValue')) {
            throw "Toggle definition '$SourcePath' state '$stateName' is missing 'StateValue' (required unless NoStateRecord is set)."
        }

        if ($stateEntry.Contains('Reboot') -and $stateEntry.Reboot -and
            @('Recommend', 'Prompt', 'None', 'RestartExplorer') -cnotcontains [string]$stateEntry.Reboot) {
            throw "Toggle definition '$SourcePath' state '$stateName' has an invalid Reboot '$($stateEntry.Reboot)'. Valid values: Recommend, Prompt, None, RestartExplorer."
        }
        if ($stateEntry.Contains('ShellRefreshOperation') -and
            ([string]$stateEntry.Reboot -cne 'RestartExplorer' -or
                @('ShellRefresh', 'ExplorerRefresh', 'SearchShellRefresh', 'ExplorerAndSettingsRefresh') `
                    -cnotcontains [string]$stateEntry.ShellRefreshOperation)) {
            throw "Toggle definition '$SourcePath' state '$stateName' has an invalid ShellRefreshOperation '$($stateEntry.ShellRefreshOperation)'."
        }
    }
}

function Get-AtlasToggleDefinition {
    <#
    .SYNOPSIS
        Locates, loads and validates a toggle definition by its setting name from
        <TogglesRoot>\<Group>\<Name>.ps1.
    #>
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

    $files = @(Get-ChildItem -LiteralPath $root -Recurse -File -Filter "$Name.ps1" |
        Where-Object { $_.BaseName -ceq $Name })
    if ($files.Count -eq 0) {
        throw "No toggle definition named '$Name' was found under '$root'."
    }
    if ($files.Count -gt 1) {
        throw "Multiple toggle definitions named '$Name' were found under '$root': $(($files | ForEach-Object { $_.FullName }) -join ', ')."
    }

    $definition = & $files[0].FullName
    Assert-AtlasToggleDefinition -Definition $definition -ExpectedName $Name -SourcePath $files[0].FullName

    return $definition
}

function Resolve-AtlasToggleStateName {
    <#
    .SYNOPSIS
        Resolves which state of a definition to run. Explicit -State wins; Menu toggles
        prompt interactively, and in silent mode fall back to the recorded state (upgrade
        re-apply) or the definition's SilentDefault.
    #>
    param(
        [Parameter(Mandatory = $true)]
        $Definition,

        [string]$State,

        [switch]$Silent,

        [string]$StateRoot
    )

    $validStates = @($Definition.States.Keys)

    if ($State) {
        if ($validStates -cnotcontains $State) {
            throw "Unknown state '$State' for toggle '$($Definition.Name)'. Valid states: $($validStates -join ', ')."
        }
        return $State
    }

    if (-not $Silent) {
        if ($Definition.Contains('Menu') -and $Definition.Menu) {
            return Show-AtlasStateMenu -Definition $Definition
        }
        throw "Toggle '$($Definition.Name)' requires a -State. Valid states: $($validStates -join ', ')."
    }

    # Silent with no explicit state: re-apply the recorded state when it maps to one.
    $stateParams = @{ Name = [string]$Definition.Name }
    if ($StateRoot) {
        $stateParams['StateRoot'] = $StateRoot
    }
    $recorded = Get-AtlasToggleState @stateParams
    if ($recorded -and $null -ne $recorded.State) {
        foreach ($stateName in $validStates) {
            $stateEntry = $Definition.States[$stateName]
            if ($stateEntry.Contains('StateValue') -and [int]$stateEntry.StateValue -eq $recorded.State) {
                return $stateName
            }
        }
    }

    if ($Definition.Contains('SilentDefault') -and $Definition.SilentDefault) {
        $silentDefault = [string]$Definition.SilentDefault
        if ($validStates -cnotcontains $silentDefault) {
            throw "Toggle '$($Definition.Name)' declares SilentDefault '$silentDefault', which is not a defined state."
        }
        return $silentDefault
    }

    throw "Toggle '$($Definition.Name)' was invoked silently without a -State and no recorded state or SilentDefault could resolve one."
}

function ConvertTo-AtlasToggleQuotedWindowsArgument {
    param(
        [Parameter(Mandatory = $true)]
        [AllowEmptyString()]
        [string]$Value
    )

    if ($Value.Length -gt 32766) {
        throw 'A toggle relaunch argument exceeded the Windows command-line value limit.'
    }

    # Start-Process joins ArgumentList into one Windows command line. Escape quotes
    # and the backslashes that precede them, then double trailing backslashes.
    $escaped = [regex]::Replace($Value, '(\\*)"', '$1$1\"')
    $escaped = [regex]::Replace($escaped, '(\\+)$', '$1$1')
    return '"' + $escaped + '"'
}

function Start-AtlasToggleAdminRelaunch {
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute(
        'PSUseShouldProcessForStateChangingFunctions',
        '',
        Justification = 'This private boundary always launches the fixed, user-confirmed elevated toggle child.'
    )]
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [string]$FilePath,

        [Parameter(Mandatory = $true)]
        [ValidateNotNull()]
        [string[]]$ArgumentList
    )

    return Microsoft.PowerShell.Management\Start-Process `
        -FilePath $FilePath `
        -ArgumentList $ArgumentList `
        -WorkingDirectory ([Environment]::GetFolderPath('System')) `
        -Verb RunAs `
        -Wait `
        -PassThru `
        -ErrorAction Stop
}

function Get-AtlasToggleRelaunchArgumentList {
    <#
    .SYNOPSIS
        Reconstructs the Invoke-Toggle.ps1 argument list used to relaunch the current
        invocation in an elevated context.
    #>
    param(
        [Parameter(Mandatory = $true)]
        [string]$Name,

        [string]$State,

        [string]$LauncherPath,

        [switch]$Silent,

        [switch]$JustContext,

        [switch]$NoExplorerRestart,

        [switch]$MachineOnly
    )

    $invokeTogglePath = Join-Path -Path (Get-AtlasContext).AtlasModulesPath -ChildPath 'Scripts\Invoke-Toggle.ps1'

    $argumentList = @(
        '-NoProfile', '-NoLogo', '-ExecutionPolicy', 'Bypass',
        '-File', (ConvertTo-AtlasToggleQuotedWindowsArgument -Value $invokeTogglePath),
        '-Name', (ConvertTo-AtlasToggleQuotedWindowsArgument -Value $Name)
    )
    if ($State) {
        $argumentList += @('-State', (ConvertTo-AtlasToggleQuotedWindowsArgument -Value $State))
    }
    if ($LauncherPath) {
        $argumentList += @('-LauncherPath', (ConvertTo-AtlasToggleQuotedWindowsArgument -Value $LauncherPath))
    }
    if ($Silent) {
        $argumentList += '/silent'
    }
    if ($JustContext) {
        $argumentList += '/justcontext'
    }
    if ($NoExplorerRestart) {
        $argumentList += '/noaction'
    }
    if ($MachineOnly) {
        $argumentList += '-MachineOnly'
    }

    return $argumentList
}

function Invoke-AtlasToggleAction {
    <#
    .SYNOPSIS
        Runs a toggle action non-strict while treating ordinary PowerShell errors as
        failures, then logs and rethrows them.
    #>
    param(
        [Parameter(Mandatory = $true)]
        [scriptblock]$Action,

        [Parameter(Mandatory = $true)]
        $ToggleContext,

        [string]$Label = 'action'
    )

    $runner = {
        param($innerAction, $innerContext)
        Set-StrictMode -Off
        $ErrorActionPreference = 'Stop'
        & $innerAction $innerContext
    }

    try {
        & $runner $Action $ToggleContext
    }
    catch {
        Write-AtlasLog -Level Warning -Message "Toggle '$($ToggleContext.Name)' $Label failed: $($_.Exception.Message)" -ErrorRecord $_
        throw
    }
}

function Get-AtlasToggleUserCallerBinding {
    <#
    .SYNOPSIS
        Captures the non-elevated account/session that owns a split UserAction.
    #>
    if ((Test-AtlasSystem) -or (Test-AtlasAdmin)) {
        throw 'A split toggle UserAction must start from the intended non-elevated user.'
    }

    $identity = [Security.Principal.WindowsIdentity]::GetCurrent()
    try {
        $sid = [string]$identity.User.Value
    }
    finally {
        $identity.Dispose()
    }
    $sidObject = New-Object Security.Principal.SecurityIdentifier($sid)
    if (-not $sidObject.IsAccountSid() -or $sid -cne $sidObject.Value -or
        $sid -in @('S-1-5-18', 'S-1-5-19', 'S-1-5-20')) {
        throw "Split toggle UserAction token SID '$sid' is not a canonical account SID."
    }

    $process = [Diagnostics.Process]::GetCurrentProcess()
    try {
        $sessionId = [int]$process.SessionId
    }
    finally {
        $process.Dispose()
    }
    if ($sessionId -lt 1) {
        throw 'A split toggle UserAction requires a nonzero interactive Windows session.'
    }

    return [pscustomobject][ordered]@{
        Sid       = $sid
        SessionId = $sessionId
    }
}

function Show-AtlasTogglePreamble {
    param(
        [Parameter(Mandatory = $true)]
        [ValidateNotNull()]
        [System.Collections.IDictionary]$Definition,

        [Parameter(Mandatory = $true)]
        [ValidateNotNull()]
        [System.Collections.IDictionary]$StateEntry,

        [string]$LauncherPath,

        [switch]$JustContext
    )

    $displayName = [string]$Definition.Name
    if ($LauncherPath) {
        $displayName = [System.IO.Path]::GetFileNameWithoutExtension($LauncherPath)
    }
    elseif ($StateEntry.Contains('Launcher') -and $StateEntry.Launcher) {
        $displayName = [System.IO.Path]::GetFileNameWithoutExtension([string]$StateEntry.Launcher)
    }
    elseif ($Definition.Contains('Launcher') -and $Definition.Launcher) {
        $displayName = [System.IO.Path]::GetFileNameWithoutExtension([string]$Definition.Launcher)
    }
    Write-Title -Text $displayName

    if (-not $JustContext -and $Definition.Contains('Warning') -and $Definition.Warning) {
        Write-Host $Definition.Warning -ForegroundColor Yellow
        Read-Pause -Message 'Press Enter to continue or Ctrl+C to cancel'
    }
}

function Invoke-AtlasTogglePostAction {
    param(
        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [string]$ToggleName,

        [Parameter(Mandatory = $true)]
        [ValidateNotNull()]
        [System.Collections.IDictionary]$StateEntry,

        [Parameter(Mandatory = $true)]
        [ValidateNotNull()]
        $Context,

        [switch]$Silent,

        [switch]$NoExplorerRestart
    )

    $reboot = 'None'
    if ($StateEntry.Contains('Reboot') -and $StateEntry.Reboot) {
        $reboot = [string]$StateEntry.Reboot
    }

    switch ($reboot) {
        'RestartExplorer' {
            if (-not $NoExplorerRestart) {
                if (Test-AtlasSystem) {
                    Write-AtlasLog -Level Warning -Message `
                        "Toggle '$ToggleName' cannot refresh an interactive shell from SYSTEM; restart Explorer in the affected user session."
                }
                else {
                    $operation = if ($StateEntry.Contains('ShellRefreshOperation')) {
                        [string]$StateEntry.ShellRefreshOperation
                    }
                    else {
                        'ExplorerRefresh'
                    }
                    Invoke-AtlasToggleCurrentSessionShellRefresh -Operation $operation
                }
            }
        }
        'Recommend' {
            if (-not $Silent) {
                Write-Host ''
                Write-Host 'Finished, please reboot your device for changes to apply.'
            }
        }
        'Prompt' {
            if (-not $Silent) {
                $answer = Read-Host 'Finished. Would you like to reboot now? (y/n)'
                if ($answer -match '^(y|yes)$') {
                    & "$($Context.WinDir)\System32\shutdown.exe" /r /t 0
                }
            }
        }
    }

    if (-not $Silent) {
        Read-Pause -Message 'Press Enter to exit'
    }
}

function Invoke-AtlasToggleInProcess {
    param(
        [Parameter(Mandatory = $true)]
        [ValidateNotNull()]
        [System.Collections.IDictionary]$Definition,

        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [string]$StateName,

        [string]$LauncherPath,

        [switch]$Silent,

        [switch]$JustContext,

        [switch]$NoExplorerRestart,

        [ValidateNotNullOrEmpty()]
        [string]$StateRoot = $script:AtlasToggleDefaultStateRoot,

        [switch]$UserContext,

        [switch]$ResetServices,

        [switch]$SkipPreamble,

        [ValidateSet('Automatic', 'Machine', 'User')]
        [string]$ActionScope = 'Automatic'
    )

    $matchingStates = @($Definition.States.Keys | Where-Object {
        [string]$_ -ceq $StateName
    })
    if ($matchingStates.Count -ne 1) {
        throw "The private toggle core requires one exact state '$StateName' for '$($Definition.Name)'."
    }
    $stateEntry = $Definition.States[$matchingStates[0]]
    $hasSplitKeys = $stateEntry.Contains('MachineAction') -or $stateEntry.Contains('UserAction')
    $isSplit = Test-AtlasToggleSplitMachineState -StateEntry $stateEntry
    if ($hasSplitKeys -and -not $isSplit) {
        throw "Toggle '$($Definition.Name)' has an invalid privileged action split."
    }
    if ($isSplit -and $ActionScope -ceq 'Automatic') {
        throw "Split toggle '$($Definition.Name)' requires an exact Machine or User action scope."
    }
    if (-not $isSplit -and $ActionScope -cne 'Automatic') {
        throw "Legacy toggle '$($Definition.Name)' does not accept a scoped Machine or User action."
    }

    if (-not $Silent -and -not $SkipPreamble) {
        Show-AtlasTogglePreamble -Definition $Definition -StateEntry $stateEntry `
            -LauncherPath $LauncherPath -JustContext:$JustContext
    }

    $stateValue = $null
    if ($stateEntry.Contains('StateValue')) {
        $stateValue = [int]$stateEntry.StateValue
    }

    $context = Get-AtlasContext
    $toggleContext = [pscustomobject]@{
        Name              = [string]$Definition.Name
        State             = $StateName
        StateValue        = $stateValue
        Silent            = [bool]$Silent
        JustContext       = [bool]$JustContext
        NoExplorerRestart = [bool]$NoExplorerRestart
        ResetServices     = [bool]$ResetServices
        StateRoot         = $StateRoot
        LauncherPath      = $LauncherPath
        WinDir            = $context.WinDir
        AtlasModulesPath  = $context.AtlasModulesPath
        ScriptsPath       = Join-Path -Path $context.AtlasModulesPath -ChildPath 'Scripts'
        WindowsBuild      = $context.WindowsBuild
    }

    if ($stateEntry.Contains('ContextAction') -and $stateEntry.ContextAction) {
        Invoke-AtlasToggleAction `
            -Action $stateEntry.ContextAction `
            -ToggleContext $toggleContext `
            -Label 'context action'
    }

    if (-not $JustContext) {
        switch ($ActionScope) {
            'Machine' {
                $action = $stateEntry.MachineAction
                $actionLabel = 'machine action'
            }
            'User' {
                $action = $stateEntry.UserAction
                $actionLabel = 'user action'
            }
            default {
                $action = $stateEntry.Action
                $actionLabel = 'action'
            }
        }
        Invoke-AtlasToggleAction -Action $action -ToggleContext $toggleContext -Label $actionLabel
    }

    $shouldRecord = -not $JustContext -and -not $UserContext -and $ActionScope -cne 'User' -and
        -not ($Definition.Contains('NoStateRecord') -and $Definition.NoStateRecord) -and
        -not ($stateEntry.Contains('NoStateRecord') -and $stateEntry.NoStateRecord)
    if ($shouldRecord) {
        Set-AtlasToggleState -Name ([string]$Definition.Name) `
            -State ([int]$stateEntry.StateValue) -StateRoot $StateRoot
    }

    if ($JustContext) {
        if (-not $Silent) {
            Read-Pause -Message 'Press Enter to exit'
        }
        return
    }

    $scopeText = if ($ActionScope -ceq 'Automatic') { '' } else { " $($ActionScope.ToLowerInvariant())" }
    Write-AtlasLog -Message "Toggle '$($Definition.Name)' applied${scopeText} state '$StateName'."
    if ($ActionScope -ceq 'Machine') {
        return
    }

    Invoke-AtlasTogglePostAction `
        -ToggleName ([string]$Definition.Name) `
        -StateEntry $stateEntry `
        -Context $context `
        -Silent:$Silent `
        -NoExplorerRestart:$NoExplorerRestart
}

function Invoke-AtlasToggleMachineDependency {
    param(
        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [string]$Name,

        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [string]$State,

        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [string]$StateRoot,

        [string]$TogglesRoot
    )

    $definition = Get-AtlasToggleDefinition -Name $Name -TogglesRoot $TogglesRoot
    $exactStates = @($definition.States.Keys | Where-Object { [string]$_ -ceq $State })
    if ($exactStates.Count -ne 1) {
        throw "Machine dependency '$Name' does not define exact state '$State'."
    }

    $elevation = if ($definition.Contains('Elevation')) {
        [string]$definition.Elevation
    }
    else {
        'None'
    }
    if ($elevation -ceq 'TrustedInstaller') {
        Assert-AtlasPrivilege -TrustedInstaller
    }
    elseif ($elevation -ceq 'Admin') {
        Assert-AtlasPrivilege -Administrator
    }
    else {
        throw "Machine dependency '$Name' does not declare exact Admin or TrustedInstaller elevation."
    }

    $stateEntry = $definition.States[$exactStates[0]]
    if (Test-AtlasToggleSplitMachineState -StateEntry $stateEntry) {
        $actionScope = 'Machine'
    }
    elseif ($stateEntry.Contains('Action') -and
        $stateEntry.Action -is [scriptblock] -and
        $stateEntry.Contains('ReplayScope') -and
        [string]$stateEntry.ReplayScope -ceq 'Machine') {
        $actionScope = 'Automatic'
    }
    else {
        throw "Machine dependency '$Name' state '$State' is not explicitly classified as machine-only."
    }

    Invoke-AtlasToggleInProcess `
        -Definition $definition `
        -StateName $State `
        -Silent `
        -NoExplorerRestart `
        -StateRoot $StateRoot `
        -ActionScope $actionScope
}

function Invoke-AtlasServiceDefaultsReset {
    <#
    .SYNOPSIS
        Applies the fixed shipped service-default plan under strict TrustedInstaller.
    .DESCRIPTION
        Private and parameterless by design. This is not a generic elevation bypass:
        both the complete definition-file set and each exact default state are pinned
        before the private in-process core can run.
    #>
    [CmdletBinding()]
    param()

    Assert-AtlasPrivilege -TrustedInstaller

    $context = Get-AtlasContext
    $servicesRoot = Join-Path -Path $context.AtlasModulesPath -ChildPath 'Toggles\Services'
    if (-not (Test-Path -LiteralPath $servicesRoot -PathType Container)) {
        throw "The fixed service-toggle definition directory is missing: '$servicesRoot'."
    }

    $definitionFiles = @(Get-ChildItem -LiteralPath $servicesRoot -File -Filter '*.ps1' |
        Sort-Object -Property Name)
    $expectedNames = @($script:AtlasServiceDefaultResetStates.Keys | ForEach-Object { [string]$_ })
    $actualNames = @($definitionFiles | ForEach-Object { [string]$_.BaseName })
    if ($actualNames.Count -ne $expectedNames.Count) {
        throw "The shipped service-toggle set does not match the closed ResetServices allowlist."
    }
    for ($index = 0; $index -lt $expectedNames.Count; $index++) {
        if ($actualNames[$index] -cne $expectedNames[$index]) {
            throw "The shipped service-toggle set does not match the closed ResetServices allowlist."
        }
    }

    $completed = @{}
    foreach ($name in $expectedNames) {
        if ($name -ceq 'NetworkDiscovery' -and
            -not $completed.ContainsKey('LanmanWorkstation')) {
            throw 'ResetServices cannot skip the NetworkDiscovery dependency before LanmanWorkstation completes.'
        }

        $definition = Get-AtlasToggleDefinition -Name $name -TogglesRoot $servicesRoot
        if (-not $definition.Contains('Elevation') -or
            [string]$definition.Elevation -cne 'Admin') {
            throw "ResetServices definition '$name' must remain an exact Administrator toggle."
        }

        $defaultStates = @($definition.States.Keys | Where-Object {
            $stateEntry = $definition.States[$_]
            $stateEntry.Contains('Launcher') -and
                ([string]$stateEntry.Launcher).IndexOf(
                    '(default)',
                    [StringComparison]::OrdinalIgnoreCase
                ) -ge 0
        })
        $expectedState = [string]$script:AtlasServiceDefaultResetStates[$name]
        if ($defaultStates.Count -ne 1 -or
            [string]$defaultStates[0] -cne $expectedState) {
            throw "ResetServices definition '$name' must declare only '$expectedState' as its '(default)' state."
        }

        Invoke-AtlasToggleInProcess `
            -Definition $definition `
            -StateName $expectedState `
            -Silent `
            -NoExplorerRestart `
            -ResetServices
        $completed[$name] = $true
    }
}

function Invoke-AtlasToggleCurrentSessionShellRefresh {
    param(
        [ValidateSet(
            'ShellRefresh',
            'ExplorerRefresh',
            'SearchShellRefresh',
            'ExplorerAndSettingsRefresh'
        )]
        [string]$Operation = 'ExplorerRefresh'
    )

    if ((Test-AtlasSystem) -or (Test-AtlasAdmin)) {
        Write-AtlasLog -Level Warning -Message `
            'Explorer was not refreshed because the toggle caller is elevated. Restart Explorer from the affected non-elevated user session, or sign out and back in.'
        return
    }

    $context = Get-AtlasContext
    $expectedModulesPath = [IO.Path]::Combine(
        [IO.Path]::GetFullPath([string]$context.WinDir),
        'AtlasModules'
    )
    $modulesPath = [IO.Path]::GetFullPath([string]$context.AtlasModulesPath)
    if (-not $modulesPath.Equals($expectedModulesPath, [StringComparison]::OrdinalIgnoreCase)) {
        throw 'The toggle shell-refresh helper is outside the protected Windows payload root.'
    }

    $helperPath = [IO.Path]::Combine($modulesPath, 'Scripts', 'Internal', 'Invoke-AtlasUserShellRefresh.ps1')
    $powerShellPath = [IO.Path]::Combine([Environment]::SystemDirectory, 'WindowsPowerShell', 'v1.0', 'powershell.exe')
    foreach ($path in @($helperPath, $powerShellPath)) {
        if (-not [IO.File]::Exists($path) -or
            (([IO.File]::GetAttributes($path) -band [IO.FileAttributes]::ReparsePoint) -ne 0)) {
            throw "Required protected toggle shell-refresh file '$path' is missing or a reparse point."
        }
    }

    & $powerShellPath -NoLogo -NoProfile -NonInteractive -ExecutionPolicy Bypass `
        -File $helperPath -CurrentSession -Operation $Operation
    if ($LASTEXITCODE -ne 0) {
        throw "Current-session toggle shell refresh exited with code $LASTEXITCODE."
    }
}

function Invoke-AtlasToggle {
    <#
    .SYNOPSIS
        Applies a toggle state: resolves the definition, elevates if needed, runs the
        state's action(s), records the chosen state under HKLM\SOFTWARE\AtlasOS\Services
        only after every requested action completes without a terminating error, and
        handles reboot/explorer-restart behavior.
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [string]$Name,

        [string]$State,

        [string]$LauncherPath,

        [switch]$Silent,

        [switch]$JustContext,

        [switch]$NoExplorerRestart,

        [string]$TogglesRoot,

        [ValidateNotNullOrEmpty()]
        [string]$StateRoot = $script:AtlasToggleDefaultStateRoot,

        [switch]$MachineOnly
    )

    $definition = Get-AtlasToggleDefinition -Name $Name -TogglesRoot $TogglesRoot
    $stateName = Resolve-AtlasToggleStateName -Definition $definition -State $State -Silent:$Silent -StateRoot $StateRoot
    $stateEntry = $definition.States[$stateName]
    $isSplitAction = Test-AtlasToggleSplitMachineState -StateEntry $stateEntry
    $deferShellRefreshToCaller = -not $NoExplorerRestart -and -not $JustContext -and
        $stateEntry.Contains('Reboot') -and
        [string]$stateEntry.Reboot -ceq 'RestartExplorer'
    $shellRefreshOperation = if ($stateEntry.Contains('ShellRefreshOperation')) {
        [string]$stateEntry.ShellRefreshOperation
    }
    else {
        'ExplorerRefresh'
    }
    $coreParams = @{
        Definition   = $definition
        StateName    = $stateName
        LauncherPath = $LauncherPath
        Silent       = $Silent
        StateRoot    = $StateRoot
    }

    $elevation = 'None'
    if ($definition.Contains('Elevation') -and $definition.Elevation) {
        $elevation = [string]$definition.Elevation
    }
    $trustedInstaller = Test-AtlasTrustedInstaller
    if ($trustedInstaller -and $elevation -cne 'TrustedInstaller') {
        throw "Toggle '$Name' does not declare exact TrustedInstaller elevation."
    }

    $userContext = $env:ATLAS_USER_CONTEXT -ceq '1'
    if ($userContext) {
        $elevation = 'None'
    }

    if ($isSplitAction -and -not $MachineOnly -and -not $userContext -and
        -not $trustedInstaller -and -not (Test-AtlasSystem) -and (Test-AtlasAdmin)) {
        throw "Split toggle '$Name' must be launched from a non-elevated user process so its UserAction cannot inherit an Administrator token."
    }

    if ($MachineOnly) {
        if (-not $isSplitAction) {
            throw "Toggle '$Name' does not declare a privileged MachineAction/UserAction split."
        }
        if ($userContext -or $JustContext) {
            throw "Toggle '$Name' cannot combine -MachineOnly with a user-context or context-only invocation."
        }
        if ($elevation -ceq 'Admin' -and -not (Test-AtlasAdmin)) {
            throw "Toggle '$Name' MachineAction requires an already elevated Administrator child."
        }
        if ($elevation -ceq 'TrustedInstaller' -and -not $trustedInstaller) {
            if (Test-AtlasSystem) {
                throw "Toggle '$Name' is running as LocalSystem without strict TrustedInstaller token evidence."
            }
            if (-not (Test-AtlasAdmin)) {
                throw "Toggle '$Name' MachineAction requires an already elevated Administrator child."
            }

            Invoke-AtlasTrustedInstaller `
                -Operation Toggle `
                -Name ([string]$definition.Name) `
                -State $stateName `
                -Silent:$true `
                -NoExplorerRestart:$true `
                -MachineOnly | Out-Null
            return
        }
        Invoke-AtlasToggleInProcess @coreParams -NoExplorerRestart -ActionScope Machine
        return
    }

    $userCallerBinding = $null
    if ($isSplitAction) {
        $userCallerBinding = Get-AtlasToggleUserCallerBinding
        if (-not $Silent) {
            Show-AtlasTogglePreamble -Definition $definition -StateEntry $stateEntry `
                -LauncherPath $LauncherPath -JustContext:$JustContext
        }
    }
    elseif ($elevation -ceq 'TrustedInstaller' -and -not $trustedInstaller -and -not $Silent) {
        Show-AtlasTogglePreamble -Definition $definition -StateEntry $stateEntry `
            -LauncherPath $LauncherPath -JustContext:$JustContext
    }

    if ($userContext -and $isSplitAction) {
        Invoke-AtlasToggleInProcess @coreParams -NoExplorerRestart:$NoExplorerRestart -UserContext `
            -SkipPreamble -ActionScope User
        return
    }

    $privilegedChildCompleted = $false
    if ($elevation -in @('Admin', 'TrustedInstaller') -and
        -not $trustedInstaller -and
        -not (Test-AtlasSystem) -and
        -not (Test-AtlasAdmin)) {
        if ($Silent) {
            $privilegeText = if ($elevation -ceq 'Admin') {
                'Administrator rights'
            }
            else {
                'TrustedInstaller elevation'
            }
            throw "Toggle '$Name' requires $privilegeText; refusing to prompt for elevation in silent mode."
        }

        Write-AtlasLog -Message 'Administrator privileges are required.'
        $argumentList = Get-AtlasToggleRelaunchArgumentList -Name $Name -State $stateName -LauncherPath $LauncherPath `
            -Silent:($Silent -or $isSplitAction -or $elevation -ceq 'TrustedInstaller') `
            -JustContext:$JustContext `
            -NoExplorerRestart:($NoExplorerRestart -or $deferShellRefreshToCaller) `
            -MachineOnly:$isSplitAction
        $powershellPath = [IO.Path]::Combine(
            (Get-AtlasContext).WinDir, 'System32', 'WindowsPowerShell', 'v1.0', 'powershell.exe'
        )
        if (-not [IO.File]::Exists($powershellPath)) {
            throw "The protected Windows PowerShell executable is missing at '$powershellPath'."
        }
        try {
            $adminProcess = Start-AtlasToggleAdminRelaunch `
                -FilePath $powershellPath `
                -ArgumentList $argumentList
        }
        catch [ComponentModel.Win32Exception] {
            if ($_.Exception.NativeErrorCode -eq 1223) {
                throw "Administrator elevation for toggle '$Name' was cancelled by the user."
            }
            throw "Administrator elevation for toggle '$Name' failed: $($_.Exception.Message)"
        }
        catch {
            throw "Administrator elevation for toggle '$Name' failed: $($_.Exception.Message)"
        }

        if ($null -eq $adminProcess -or
            $null -eq $adminProcess.PSObject.Properties['ExitCode'] -or
            $null -eq $adminProcess.ExitCode) {
            throw "The elevated child for toggle '$Name' returned no process exit code."
        }
        if ([int]$adminProcess.ExitCode -ne 0) {
            $failure = [InvalidOperationException]::new(
                "Elevated toggle '$Name' exited with code $($adminProcess.ExitCode)."
            )
            $failure.Data['Atlas.Toggle.AdminChildExitCode'] = [int]$adminProcess.ExitCode
            throw $failure
        }
        $privilegedChildCompleted = $true
    }
    elseif ($elevation -ceq 'TrustedInstaller' -and (Test-AtlasSystem) -and -not $trustedInstaller) {
        throw "Toggle '$Name' is running as LocalSystem without strict TrustedInstaller token evidence."
    }
    elseif ($elevation -ceq 'TrustedInstaller' -and -not $trustedInstaller) {
        if ($Silent -and -not (Test-AtlasAdmin)) {
            throw "Toggle '$Name' requires TrustedInstaller and the current process is not elevated; refusing to elevate in silent mode."
        }

        Invoke-AtlasTrustedInstaller `
            -Operation Toggle `
            -Name ([string]$definition.Name) `
            -State $stateName `
            -Silent:$true `
            -JustContext:$JustContext `
            -NoExplorerRestart:($NoExplorerRestart -or $deferShellRefreshToCaller) `
            -MachineOnly:$isSplitAction | Out-Null
        $privilegedChildCompleted = $true
    }

    if ($privilegedChildCompleted) {
        if ($isSplitAction) {
            $actualBinding = Get-AtlasToggleUserCallerBinding
            if ([string]$actualBinding.Sid -cne [string]$userCallerBinding.Sid -or
                [int]$actualBinding.SessionId -ne [int]$userCallerBinding.SessionId) {
                throw 'The split toggle caller identity or Windows session changed across the privileged machine action.'
            }
            Invoke-AtlasToggleInProcess @coreParams -NoExplorerRestart:$NoExplorerRestart `
                -SkipPreamble -ActionScope User
        }
        elseif ($elevation -ceq 'TrustedInstaller') {
            if ($JustContext) {
                if (-not $Silent) {
                    Read-Pause -Message 'Press Enter to exit'
                }
            }
            else {
                Invoke-AtlasTogglePostAction `
                    -ToggleName ([string]$definition.Name) `
                    -StateEntry $stateEntry `
                    -Context (Get-AtlasContext) `
                    -Silent:$Silent `
                    -NoExplorerRestart:$NoExplorerRestart
            }
        }
        elseif ($deferShellRefreshToCaller) {
            Invoke-AtlasToggleCurrentSessionShellRefresh -Operation $shellRefreshOperation
        }
        return
    }

    Invoke-AtlasToggleInProcess @coreParams `
        -JustContext:$JustContext `
        -NoExplorerRestart:$NoExplorerRestart `
        -UserContext:$userContext
}
