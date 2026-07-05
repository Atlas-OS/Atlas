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
# not abort it); thrown errors are logged as warnings.

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

    if ([string]$Definition.Name -ne $ExpectedName) {
        throw "Toggle definition '$SourcePath' declares Name '$($Definition.Name)' but its file name requires '$ExpectedName'."
    }

    if ($Definition.Contains('Elevation') -and $Definition.Elevation -and
        @('Admin', 'TrustedInstaller', 'None') -notcontains [string]$Definition.Elevation) {
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
            @('Recommend', 'Prompt', 'None', 'RestartExplorer') -notcontains [string]$stateEntry.Reboot) {
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
        Where-Object { $_.BaseName -eq $Name })
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
        if ($validStates -notcontains $State) {
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
        if ($validStates -notcontains $silentDefault) {
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
        '-Name', $Name
    )
    if ($State) {
        $argumentList += @('-State', $State)
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
        $ErrorActionPreference = 'Continue', logging failures as warnings.
    #>
    param(
        [Parameter(Mandatory = $true)]
        [scriptblock]$Action,

        [Parameter(Mandatory = $true)]
        $ToggleContext,

        [string]$Label = 'action',

        # Optional out-flag so callers can react to failure without disturbing the
        # action's output stream (which flows through to the console).
        [ref]$Succeeded
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
        if ($null -ne $Succeeded) {
            $Succeeded.Value = $true
        }
    }
    catch {
        Write-AtlasLog -Level Warning -Message "Toggle '$($ToggleContext.Name)' $Label failed: $($_.Exception.Message)" -ErrorRecord $_
        if ($null -ne $Succeeded) {
            $Succeeded.Value = $false
        }
    }
}

function Invoke-AtlasToggle {
    <#
    .SYNOPSIS
        Applies a toggle state: resolves the definition, elevates if needed, runs the
        state's action(s), records the chosen state under HKLM\SOFTWARE\AtlasOS\Services
        unless the action threw a terminating error, and handles reboot/explorer-restart
        behavior.
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
    $stateEntry = $definition.States[$stateName]

    # --- Elevation: the launcher never elevates; the engine does. ---------------------
    $elevation = 'None'
    if ($definition.Contains('Elevation') -and $definition.Elevation) {
        $elevation = [string]$definition.Elevation
    }

    # Initialize-NewUser.ps1 sets ATLAS_USER_CONTEXT=1 while re-applying per-user toggles
    # at first logon, where the process is never elevated. Those actions only write HKCU,
    # so run them in-process; the HKLM state record is skipped (the install wrote it).
    $userContext = $env:ATLAS_USER_CONTEXT -eq '1'
    if ($userContext) {
        $elevation = 'None'
    }

    if ($elevation -eq 'Admin' -and -not (Test-AtlasAdmin)) {
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

    if ($elevation -eq 'TrustedInstaller' -and -not (Test-AtlasTrustedInstaller)) {
        # RunAsTI works without any UI from an elevated context, so silent invocations
        # (upgrade re-apply) may still relaunch as long as they are already admin.
        if ($Silent -and -not (Test-AtlasAdmin)) {
            throw "Toggle '$Name' requires TrustedInstaller and the current process is not elevated; refusing to elevate in silent mode."
        }

        $argumentList = Get-AtlasToggleRelaunchArgumentList -Name $Name -State $stateName -LauncherPath $LauncherPath `
            -Silent:$Silent -JustContext:$JustContext -NoExplorerRestart:$NoExplorerRestart
        Invoke-AtlasTrustedInstaller -CommandLine ('powershell ' + ($argumentList -join ' ')) | Out-Null
        return
    }

    # --- State recording (compatibility contract with existing installs). --------------
    # Recorded unless the action THREW: actions run non-strict with
    # $ErrorActionPreference = 'Continue' (see Invoke-AtlasToggleAction), so
    # non-terminating cmdlet errors do NOT block recording - toggles are best-effort by
    # design. A cancelled prompt or a thrown error never records a state that upgrade
    # re-apply would replay. Actions that must gate recording on a condition should
    # detect it and `throw`.
    $noStateRecord = $userContext -or
        ($definition.Contains('NoStateRecord') -and $definition.NoStateRecord) -or
        ($stateEntry.Contains('NoStateRecord') -and $stateEntry.NoStateRecord)
    $recordState = {
        if ($noStateRecord) {
            return
        }

        $recordPath = $LauncherPath
        if (-not $recordPath) {
            $launcherRelative = $null
            if ($stateEntry.Contains('Launcher') -and $stateEntry.Launcher) {
                $launcherRelative = [string]$stateEntry.Launcher
            }
            elseif ($definition.Contains('Launcher') -and $definition.Launcher) {
                $launcherRelative = [string]$definition.Launcher
            }
            if ($launcherRelative) {
                $recordPath = Join-Path -Path (Get-AtlasContext).WinDir -ChildPath (Join-Path -Path 'AtlasDesktop' -ChildPath $launcherRelative)
            }
        }

        if ($recordPath) {
            Set-AtlasToggleState -Name ([string]$definition.Name) -State ([int]$stateEntry.StateValue) -LauncherPath $recordPath -StateRoot $StateRoot
        }
        else {
            Write-AtlasLog -Level Warning -Message "Toggle '$Name' state was not recorded: no launcher path is known."
        }
    }

    # --- Interactive title + warning confirmation. ------------------------------------
    if (-not $Silent) {
        $displayName = [string]$definition.Name
        if ($LauncherPath) {
            $displayName = [System.IO.Path]::GetFileNameWithoutExtension($LauncherPath)
        }
        elseif ($stateEntry.Contains('Launcher') -and $stateEntry.Launcher) {
            $displayName = [System.IO.Path]::GetFileNameWithoutExtension([string]$stateEntry.Launcher)
        }
        elseif ($definition.Contains('Launcher') -and $definition.Launcher) {
            $displayName = [System.IO.Path]::GetFileNameWithoutExtension([string]$definition.Launcher)
        }
        Write-Title -Text $displayName

        if (-not $JustContext -and $definition.Contains('Warning') -and $definition.Warning) {
            Write-Host $definition.Warning -ForegroundColor Yellow
            Read-Pause -Message 'Press Enter to continue or Ctrl+C to cancel'
        }
    }

    # --- Run the state's action(s). ----------------------------------------------------
    $stateValue = $null
    if ($stateEntry.Contains('StateValue')) {
        $stateValue = [int]$stateEntry.StateValue
    }

    $context = Get-AtlasContext
    $toggleContext = [pscustomobject]@{
        Name              = [string]$definition.Name
        State             = $stateName
        StateValue        = $stateValue
        Silent            = [bool]$Silent
        JustContext       = [bool]$JustContext
        NoExplorerRestart = [bool]$NoExplorerRestart
        LauncherPath      = $LauncherPath
        WinDir            = $context.WinDir
        AtlasModulesPath  = $context.AtlasModulesPath
        ScriptsPath       = Join-Path -Path $context.AtlasModulesPath -ChildPath 'Scripts'
        WindowsBuild      = $context.WindowsBuild
    }

    if ($stateEntry.Contains('ContextAction') -and $stateEntry.ContextAction) {
        Invoke-AtlasToggleAction -Action $stateEntry.ContextAction -ToggleContext $toggleContext -Label 'context action'
    }

    if ($JustContext) {
        # -JustContext still records the state even though the main action never runs
        # (launcher contract).
        & $recordState
        if (-not $Silent) {
            Read-Pause -Message 'Press Enter to exit'
        }
        return
    }

    $actionSucceeded = $true
    Invoke-AtlasToggleAction -Action $stateEntry.Action -ToggleContext $toggleContext -Succeeded ([ref]$actionSucceeded)
    if ($actionSucceeded) {
        & $recordState
        Write-AtlasLog -Message "Toggle '$Name' applied: state '$stateName'."
    }
    else {
        Write-AtlasLog -Level Warning -Message "Toggle '$Name' state was not recorded because its action failed."
    }

    # --- Reboot / explorer restart handling. -------------------------------------------
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
