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
#               ContextAction = { ... }   # optional, runs before Action; -JustContext
#                                         # stops after it
#               NoStateRecord = $true     # optional, per-state variant
#           }
#       }
#   }
#
# The launcher never elevates - the engine does. Action blocks run non-strict with
# $ErrorActionPreference = 'Continue' (individual command failures inside an action do
# not abort it); terminating errors are logged and rethrown to the caller.

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

    if (-not $Definition.Contains('States') -or $Definition.States -isnot [System.Collections.IDictionary] -or $Definition.States.Count -eq 0) {
        throw "Toggle definition '$SourcePath' is missing a non-empty 'States' hashtable."
    }

    $definitionNoRecord = $Definition.Contains('NoStateRecord') -and $Definition.NoStateRecord
    foreach ($stateName in @($Definition.States.Keys)) {
        $stateEntry = $Definition.States[$stateName]
        if ($stateEntry -isnot [System.Collections.IDictionary]) {
            throw "Toggle definition '$SourcePath' state '$stateName' is not a hashtable."
        }

        if (-not $stateEntry.Contains('Action') -or $stateEntry.Action -isnot [scriptblock]) {
            throw "Toggle definition '$SourcePath' state '$stateName' is missing an 'Action' scriptblock."
        }

        $stateNoRecord = $stateEntry.Contains('NoStateRecord') -and $stateEntry.NoStateRecord
        if (-not $definitionNoRecord -and -not $stateNoRecord -and -not $stateEntry.Contains('StateValue')) {
            throw "Toggle definition '$SourcePath' state '$stateName' is missing 'StateValue' (required unless NoStateRecord is set)."
        }

        if ($stateEntry.Contains('Reboot') -and $stateEntry.Reboot -and
            @('Recommend', 'Prompt', 'None', 'RestartExplorer') -cnotcontains [string]$stateEntry.Reboot) {
            throw "Toggle definition '$SourcePath' state '$stateName' has an invalid Reboot '$($stateEntry.Reboot)'. Valid values: Recommend, Prompt, None, RestartExplorer."
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

        [switch]$NoExplorerRestart
    )

    $invokeTogglePath = Join-Path -Path (Get-AtlasContext).AtlasModulesPath -ChildPath 'Scripts\Invoke-Toggle.ps1'

    $argumentList = @(
        '-NoProfile', '-NoLogo', '-ExecutionPolicy', 'Bypass',
        '-File', ('"{0}"' -f $invokeTogglePath),
        '-Name', ('"{0}"' -f $Name)
    )
    if ($State) {
        $argumentList += @('-State', ('"{0}"' -f $State))
    }
    if ($LauncherPath) {
        $argumentList += @('-LauncherPath', ('"{0}"' -f $LauncherPath))
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

    return $argumentList
}

function Invoke-AtlasToggleAction {
    <#
    .SYNOPSIS
        Runs a toggle Action/ContextAction scriptblock non-strict with
        $ErrorActionPreference = 'Continue', logging and rethrowing terminating errors.
    #>
    param(
        [Parameter(Mandatory = $true)]
        [scriptblock]$Action,

        [Parameter(Mandatory = $true)]
        $ToggleContext,

        [string]$Label = 'action'
    )

    # SEAM: a stricter per-toggle opt-in (e.g. a definition key that runs the action
    # with $ErrorActionPreference = 'Stop') would slot in here; deferred deliberately -
    # see plans/010-toggle-success-contract.md.
    $runner = {
        param($innerAction, $innerContext)
        Set-StrictMode -Off
        $ErrorActionPreference = 'Continue'
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

function Invoke-AtlasToggleInProcess {
    <#
    .SYNOPSIS
        Runs one already-authorized, already-resolved toggle state in the current process.
    .DESCRIPTION
        This is a private execution core. Invoke-AtlasToggle owns the public elevation
        decision. Invoke-AtlasServiceDefaultsReset is the only other caller and supplies
        a closed, parameterless, strict-TrustedInstaller reset plan.
    #>
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

        [switch]$ResetServices
    )

    $matchingStates = @($Definition.States.Keys | Where-Object {
        [string]$_ -ceq $StateName
    })
    if ($matchingStates.Count -ne 1) {
        throw "The private toggle core requires one exact state '$StateName' for '$($Definition.Name)'."
    }
    $stateEntry = $Definition.States[$matchingStates[0]]

    # Recorded only after ContextAction and Action complete without THROWING: actions run
    # non-strict with $ErrorActionPreference = 'Continue' (see Invoke-AtlasToggleAction), so
    # non-terminating cmdlet errors do NOT block recording - toggles are best-effort by
    # design. A cancelled prompt or a thrown error never records a state that upgrade
    # re-apply would replay. Actions that must gate recording on a condition should throw.
    $noStateRecord = [bool]$UserContext -or
        ($Definition.Contains('NoStateRecord') -and $Definition.NoStateRecord) -or
        ($stateEntry.Contains('NoStateRecord') -and $stateEntry.NoStateRecord)
    $recordState = {
        if ($noStateRecord) {
            return
        }

        Set-AtlasToggleState `
            -Name ([string]$Definition.Name) `
            -State ([int]$stateEntry.StateValue) `
            -StateRoot $StateRoot
    }

    if (-not $Silent) {
        $displayName = [string]$Definition.Name
        if ($LauncherPath) {
            $displayName = [System.IO.Path]::GetFileNameWithoutExtension($LauncherPath)
        }
        elseif ($stateEntry.Contains('Launcher') -and $stateEntry.Launcher) {
            $displayName = [System.IO.Path]::GetFileNameWithoutExtension([string]$stateEntry.Launcher)
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

    if ($JustContext) {
        & $recordState
        if (-not $Silent) {
            Read-Pause -Message 'Press Enter to exit'
        }
        return
    }

    Invoke-AtlasToggleAction -Action $stateEntry.Action -ToggleContext $toggleContext
    & $recordState
    Write-AtlasLog -Message "Toggle '$($Definition.Name)' applied: state '$StateName'."

    $reboot = 'None'
    if ($stateEntry.Contains('Reboot') -and $stateEntry.Reboot) {
        $reboot = [string]$stateEntry.Reboot
    }

    switch ($reboot) {
        'RestartExplorer' {
            if (-not $NoExplorerRestart) {
                Stop-Process -Name 'explorer' -Force -ErrorAction SilentlyContinue
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
                    & "$($context.WinDir)\System32\shutdown.exe" /r /t 0
                }
            }
        }
    }

    if (-not $Silent) {
        Read-Pause -Message 'Press Enter to exit'
    }
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
        [string]$StateRoot = $script:AtlasToggleDefaultStateRoot
    )

    $definition = Get-AtlasToggleDefinition -Name $Name -TogglesRoot $TogglesRoot
    $stateName = Resolve-AtlasToggleStateName -Definition $definition -State $State -Silent:$Silent -StateRoot $StateRoot

    # A strict TrustedInstaller token is a privileged execution sink, not a general
    # substitute for Administrator. Defense in depth mirrors the broker allowlist:
    # only definitions that declare this exact authority may reach their actions.
    if ((Test-AtlasTrustedInstaller) -and
        (-not $definition.Contains('Elevation') -or
            [string]$definition.Elevation -cne 'TrustedInstaller')) {
        throw "Toggle '$Name' does not declare exact TrustedInstaller elevation."
    }

    # --- Elevation: the launcher never elevates; the engine does. ---------------------
    $elevation = 'None'
    if ($definition.Contains('Elevation') -and $definition.Elevation) {
        $elevation = [string]$definition.Elevation
    }

    # Initialize-NewUser.ps1 sets ATLAS_USER_CONTEXT=1 while re-applying per-user toggles
    # at first logon, where the process is never elevated. Those actions only write HKCU,
    # so run them in-process; the HKLM state record is skipped (the install wrote it).
    $userContext = $env:ATLAS_USER_CONTEXT -ceq '1'
    if ($userContext) {
        $elevation = 'None'
    }

    if ($elevation -ceq 'Admin' -and -not (Test-AtlasAdmin)) {
        if ($Silent) {
            throw "Toggle '$Name' requires Administrator rights; refusing to prompt for elevation in silent mode."
        }

        Write-AtlasLog -Message 'Administrator privileges are required.'
        $argumentList = Get-AtlasToggleRelaunchArgumentList -Name $Name -State $stateName -LauncherPath $LauncherPath `
            -Silent:$Silent -JustContext:$JustContext -NoExplorerRestart:$NoExplorerRestart
        try {
            Start-Process -FilePath 'powershell' -ArgumentList $argumentList -Verb RunAs | Out-Null
        }
        catch {
            throw "You must run this toggle as admin. Elevation failed: $($_.Exception.Message)"
        }
        return
    }

    if ($elevation -ceq 'TrustedInstaller' -and
        (Test-AtlasSystem) -and -not (Test-AtlasTrustedInstaller)) {
        throw "Toggle '$Name' is running as LocalSystem without strict TrustedInstaller token evidence."
    }

    if ($elevation -ceq 'TrustedInstaller' -and -not (Test-AtlasTrustedInstaller)) {
        # The closed broker operation is always noninteractive. Silent upgrade
        # re-application may use it only from an already elevated caller; an
        # interactive invocation can still request UAC consent through the broker.
        if ($Silent -and -not (Test-AtlasAdmin)) {
            throw "Toggle '$Name' requires TrustedInstaller and the current process is not elevated; refusing to elevate in silent mode."
        }

        $result = Invoke-AtlasTrustedInstaller `
            -Operation Toggle `
            -Name ([string]$definition.Name) `
            -State $stateName `
            -Silent:$true `
            -JustContext:$JustContext `
            -NoExplorerRestart:$NoExplorerRestart

        if ($null -eq $result -or $null -eq $result.PSObject.Properties['status']) {
            throw "TrustedInstaller toggle '$Name' returned no structured broker result."
        }
        if ([string]$result.status -cne 'Completed') {
            $failure = if ($null -ne $result.PSObject.Properties['error'] -and
                -not [string]::IsNullOrWhiteSpace([string]$result.error)) {
                [string]$result.error
            }
            else {
                'No broker error detail was returned.'
            }
            throw "TrustedInstaller toggle '$Name' failed with status '$($result.status)': $failure"
        }
        if ($null -eq $result.PSObject.Properties['exitCodeUInt32'] -or
            $null -eq $result.exitCodeUInt32) {
            throw "TrustedInstaller toggle '$Name' completed without an exit code."
        }
        if ([uint64]$result.exitCodeUInt32 -ne 0) {
            throw "TrustedInstaller toggle '$Name' exited with code $($result.exitCodeUInt32)."
        }
        return
    }

    Invoke-AtlasToggleInProcess `
        -Definition $definition `
        -StateName $stateName `
        -LauncherPath $LauncherPath `
        -Silent:$Silent `
        -JustContext:$JustContext `
        -NoExplorerRestart:$NoExplorerRestart `
        -StateRoot $StateRoot `
        -UserContext:$userContext
}
