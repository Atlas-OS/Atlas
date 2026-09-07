# Atlas.Toggles domain: the toggle engine.
#
# Definition.ps1 loads and classifies a toggle; this file runs it. A state's work is
# split by where it must execute (see Definition.ps1): machine work runs under the
# declared elevation and is recorded, user work runs in the launching user's own
# non-elevated process, and an Elevation = 'None' toggle runs everything locally.
#
# The launcher never elevates - the engine does. Companion functions run under strict
# mode with terminating errors, so a failed action can never be recorded as applied.

$script:AtlasServiceDefaultResetStates = [ordered]@{
    Bluetooth                        = 'Enable'
    LanmanWorkstation                = 'Enable'
    NetworkDiscovery                 = 'Enable'
    NVidiaDisplayContainer           = 'Enable'
    NVidiaDisplayContainerContextMenu = 'Disable'
    Printing                         = 'Enable'
    SuperFetch                       = 'Enable'
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
        [System.Collections.IDictionary]$Definition,

        [string]$State,

        [switch]$Silent,

        [string]$StateRoot
    )

    $validStates = @($Definition['States'].Keys | ForEach-Object { [string]$_ })

    if ($State) {
        if ($validStates -cnotcontains $State) {
            throw "Unknown state '$State' for toggle '$($Definition['Name'])'. Valid states: $($validStates -join ', ')."
        }
        return $State
    }

    if (-not $Silent) {
        if ($Definition.Contains('Menu') -and [bool]$Definition['Menu']) {
            return Show-AtlasStateMenu -Definition $Definition
        }
        throw "Toggle '$($Definition['Name'])' requires a -State. Valid states: $($validStates -join ', ')."
    }

    # Silent with no explicit state: re-apply the recorded state when it maps to one.
    $stateParams = @{ Name = [string]$Definition['Name'] }
    if ($StateRoot) {
        $stateParams['StateRoot'] = $StateRoot
    }
    $recorded = Get-AtlasToggleState @stateParams
    if ($recorded -and $null -ne $recorded.State) {
        foreach ($stateName in $validStates) {
            $stateEntry = $Definition['States'][$stateName]
            if ($stateEntry.Contains('StateValue') -and [int]$stateEntry['StateValue'] -eq $recorded.State) {
                return $stateName
            }
        }
    }

    if ($Definition.Contains('SilentDefault') -and $Definition['SilentDefault']) {
        return [string]$Definition['SilentDefault']
    }

    throw "Toggle '$($Definition['Name'])' was invoked silently without a -State and no recorded state or SilentDefault could resolve one."
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

    $invokeTogglePath = Join-Path -Path (Get-AtlasContext).AtlasModulesPath -ChildPath 'Scripts\Entry\Invoke-Toggle.ps1'

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

function Invoke-AtlasToggleElevatedChild {
    <#
    .SYNOPSIS
        Relaunches Invoke-Toggle.ps1 through UAC and waits for it. A nonzero child exit
        code is rethrown with the code attached so the CLI boundary can propagate it.
    #>
    param(
        [Parameter(Mandatory = $true)]
        [string]$Name,

        [Parameter(Mandatory = $true)]
        [string[]]$ArgumentList,

        [switch]$Silent
    )

    $powershellPath = [IO.Path]::Combine(
        (Get-AtlasContext).WinDir, 'System32', 'WindowsPowerShell', 'v1.0', 'powershell.exe'
    )
    if (-not [IO.File]::Exists($powershellPath)) {
        throw "The protected Windows PowerShell executable is missing at '$powershellPath'."
    }

    Write-AtlasLog -Message 'Administrator privileges are required.'
    if (-not $Silent) {
        Write-AtlasStep -Text 'Asking for administrator permission...'
    }
    try {
        $adminProcess = Start-AtlasToggleAdminRelaunch -FilePath $powershellPath -ArgumentList $ArgumentList
    }
    catch [ComponentModel.Win32Exception] {
        if ($_.Exception.NativeErrorCode -eq 1223) {
            throw "The administrator permission prompt for '$Name' was cancelled, so nothing was changed."
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
            "The administrator step for '$Name' did not complete (exit code $($adminProcess.ExitCode)). Its window shows the reason."
        )
        $failure.Data['Atlas.Toggle.AdminChildExitCode'] = [int]$adminProcess.ExitCode
        throw $failure
    }
}

function New-AtlasToggleContext {
    <#
    .SYNOPSIS
        Builds the $Toggle object handed to every companion function.
    #>
    param(
        [Parameter(Mandatory = $true)]
        [System.Collections.IDictionary]$Definition,

        [Parameter(Mandatory = $true)]
        [string]$StateName,

        [switch]$Silent,
        [switch]$JustContext,
        [switch]$NoExplorerRestart,
        [switch]$ResetServices,
        [string]$StateRoot,
        [string]$LauncherPath
    )

    $stateEntry = $Definition['States'][$StateName]
    $stateValue = $null
    if ($stateEntry.Contains('StateValue')) {
        $stateValue = [int]$stateEntry['StateValue']
    }

    $context = Get-AtlasContext
    $scriptsPath = Join-Path -Path $context.AtlasModulesPath -ChildPath 'Scripts'
    return [pscustomobject]@{
        Name              = [string]$Definition['Name']
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
        ScriptsPath       = $scriptsPath
        ModulesPath       = Join-Path -Path $scriptsPath -ChildPath 'Modules'
        OperationsPath    = Join-Path -Path $scriptsPath -ChildPath 'Operations'
        WindowsBuild      = $context.WindowsBuild
    }
}

function Invoke-AtlasToggleFunction {
    <#
    .SYNOPSIS
        Runs one named companion function. The companion script is dot-sourced into
        this function's own scope, so its functions exist only for this call, and the
        named function runs under strict mode with terminating errors. Failures are
        logged and rethrown.
    #>
    param(
        [Parameter(Mandatory = $true)]
        [System.Collections.IDictionary]$Definition,

        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [string]$FunctionName,

        [Parameter(Mandatory = $true)]
        $Toggle,

        [string]$Label = 'action'
    )

    $companion = [string]$Definition['ScriptPath']
    if ([string]::IsNullOrWhiteSpace($companion) -or -not [IO.File]::Exists($companion)) {
        throw "Toggle '$($Definition['Name'])' names companion function '$FunctionName' but has no companion script."
    }
    if (@($Definition['Functions']) -cnotcontains $FunctionName) {
        throw "Toggle '$($Definition['Name'])' companion script does not define '$FunctionName'."
    }

    $runner = {
        param($CompanionPath, $Name, $ToggleContext)
        Set-StrictMode -Version 3.0
        $ErrorActionPreference = 'Stop'
        . $CompanionPath
        & $Name -Toggle $ToggleContext
    }

    try {
        & $runner $companion $FunctionName $Toggle
    }
    catch {
        Write-AtlasLog -Level Warning -Message "Toggle '$($Toggle.Name)' $Label '$FunctionName' failed: $($_.Exception.Message)" -ErrorRecord $_
        throw
    }
}

function Invoke-AtlasToggleScopedWork {
    <#
    .SYNOPSIS
        Applies exactly the part of a state that belongs to one execution scope.
    .DESCRIPTION
        Machine: HKLM registry entries, Services, ScheduledTasks, then MachineAction.
        User:    HKCU registry entries through the ambient user hive, then UserAction.
        Local:   every registry entry, then Action (Elevation = 'None' toggles only).
    #>
    param(
        [Parameter(Mandatory = $true)]
        [System.Collections.IDictionary]$Definition,

        [Parameter(Mandatory = $true)]
        [System.Collections.IDictionary]$StateEntry,

        [Parameter(Mandatory = $true)]
        $Toggle,

        [Parameter(Mandatory = $true)]
        [ValidateSet('Machine', 'User', 'Local')]
        [string]$Scope
    )

    $registry = @()
    if (Test-AtlasToggleStateHasKey -StateEntry $StateEntry -Key 'Registry') {
        $registry = @($StateEntry['Registry'] | ForEach-Object { [hashtable]$_ })
    }

    switch ($Scope) {
        'Machine' {
            if ($registry.Count -gt 0) {
                Invoke-AtlasRegistryEntries -Entries $registry -Scope Machine
            }
            if (Test-AtlasToggleStateHasKey -StateEntry $StateEntry -Key 'Services') {
                Invoke-AtlasServiceEntries -Entries @($StateEntry['Services'] | ForEach-Object { [hashtable]$_ })
            }
            if (Test-AtlasToggleStateHasKey -StateEntry $StateEntry -Key 'ScheduledTasks') {
                Invoke-AtlasScheduledTaskEntries -Entries @($StateEntry['ScheduledTasks'] | ForEach-Object { [hashtable]$_ })
            }
            if (Test-AtlasToggleStateHasKey -StateEntry $StateEntry -Key 'MachineAction') {
                Invoke-AtlasToggleFunction -Definition $Definition -FunctionName ([string]$StateEntry['MachineAction']) `
                    -Toggle $Toggle -Label 'machine action'
            }
        }
        'User' {
            if ($registry.Count -gt 0) {
                Invoke-AtlasRegistryEntries -Entries $registry -Scope CurrentUser
            }
            if (Test-AtlasToggleStateHasKey -StateEntry $StateEntry -Key 'UserAction') {
                Invoke-AtlasToggleFunction -Definition $Definition -FunctionName ([string]$StateEntry['UserAction']) `
                    -Toggle $Toggle -Label 'user action'
            }
        }
        'Local' {
            if ($registry.Count -gt 0) {
                Invoke-AtlasRegistryEntries -Entries $registry -Scope All
            }
            if (Test-AtlasToggleStateHasKey -StateEntry $StateEntry -Key 'Action') {
                Invoke-AtlasToggleFunction -Definition $Definition -FunctionName ([string]$StateEntry['Action']) `
                    -Toggle $Toggle -Label 'action'
            }
        }
    }
}

function Get-AtlasToggleUserCallerBinding {
    <#
    .SYNOPSIS
        Captures the non-elevated account and session that owns a state's user work.
    #>
    if ((Test-AtlasSystem) -or (Test-AtlasAdmin)) {
        throw 'The user part of a toggle must start from the intended non-elevated user.'
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
        throw "Toggle user-work token SID '$sid' is not a canonical account SID."
    }

    $process = [Diagnostics.Process]::GetCurrentProcess()
    try {
        $sessionId = [int]$process.SessionId
    }
    finally {
        $process.Dispose()
    }
    if ($sessionId -lt 1) {
        throw 'The user part of a toggle requires a nonzero interactive Windows session.'
    }

    return [pscustomobject][ordered]@{
        Sid       = $sid
        SessionId = $sessionId
    }
}

function Get-AtlasToggleDisplayName {
    <#
    .SYNOPSIS
        The name a user knows this run by: the launcher they opened, or for a Menu
        toggle's closing line the label of the state they chose.
    #>
    param(
        [Parameter(Mandatory = $true)]
        [System.Collections.IDictionary]$Definition,

        [Parameter(Mandatory = $true)]
        [System.Collections.IDictionary]$StateEntry,

        [string]$LauncherPath,

        [switch]$PreferMenuLabel
    )

    if ($PreferMenuLabel -and $Definition.Contains('Menu') -and [bool]$Definition['Menu'] -and
        $StateEntry.Contains('MenuLabel') -and $StateEntry['MenuLabel']) {
        return [string]$StateEntry['MenuLabel']
    }
    if ($LauncherPath) {
        return [IO.Path]::GetFileNameWithoutExtension($LauncherPath)
    }
    if ($StateEntry.Contains('Launcher') -and $StateEntry['Launcher']) {
        return [IO.Path]::GetFileNameWithoutExtension([string]$StateEntry['Launcher'])
    }
    if ($Definition.Contains('Launcher') -and $Definition['Launcher']) {
        return [IO.Path]::GetFileNameWithoutExtension([string]$Definition['Launcher'])
    }
    return [string]$Definition['Name']
}

function Show-AtlasTogglePreamble {
    param(
        [Parameter(Mandatory = $true)]
        [System.Collections.IDictionary]$Definition,

        [Parameter(Mandatory = $true)]
        [System.Collections.IDictionary]$StateEntry,

        [string]$LauncherPath,

        [switch]$JustContext,

        # The caller already printed the heading (a Menu toggle shows it before its menu).
        [switch]$SkipTitle
    )

    if (-not $SkipTitle) {
        Write-AtlasTitle -Text (Get-AtlasToggleDisplayName -Definition $Definition -StateEntry $StateEntry -LauncherPath $LauncherPath)
    }

    if (-not $JustContext -and $Definition.Contains('Warning') -and $Definition['Warning']) {
        Write-AtlasWarning -Text ([string]$Definition['Warning'])
        Wait-AtlasContinue
    }
}

function Invoke-AtlasTogglePostAction {
    <#
    .SYNOPSIS
        The interactive close of a run: the Explorer refresh, the one closing line, the
        restart follow-up the state declares and the single exit pause. Silent callers
        get only the Explorer refresh.
    #>
    param(
        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [string]$ToggleName,

        [Parameter(Mandatory = $true)]
        [System.Collections.IDictionary]$StateEntry,

        [Parameter(Mandatory = $true)]
        $Context,

        [switch]$Silent,

        [switch]$NoExplorerRestart,

        # The name the closing line uses; defaults to the toggle name.
        [string]$Title
    )

    if ([string]::IsNullOrWhiteSpace($Title)) {
        $Title = $ToggleName
    }

    $reboot = 'None'
    if ($StateEntry.Contains('Reboot') -and $StateEntry['Reboot']) {
        $reboot = [string]$StateEntry['Reboot']
    }

    if ($reboot -ceq 'RestartExplorer' -and -not $NoExplorerRestart) {
        if (Test-AtlasSystem) {
            Write-AtlasLog -Level Warning -Message `
                "Toggle '$ToggleName' cannot refresh an interactive shell from SYSTEM; restart Explorer in the affected user session."
        }
        else {
            $operation = 'ExplorerRefresh'
            if ($StateEntry.Contains('ShellRefreshOperation')) {
                $operation = [string]$StateEntry['ShellRefreshOperation']
            }
            if (-not $Silent) {
                Write-AtlasStep -Text 'Restarting File Explorer...'
            }
            Invoke-AtlasToggleCurrentSessionShellRefresh -Operation $operation -Silent:$Silent
        }
    }

    if ($Silent) {
        return
    }

    Write-AtlasCompletion -Title $Title
    switch ($reboot) {
        'Recommend' {
            Write-AtlasRestartNotice -Kind Recommended
        }
        'Prompt' {
            Write-AtlasRestartNotice -Kind Required
            if (Read-AtlasYesNo -Question 'Restart Windows now?') {
                Write-AtlasStep -Text 'Restarting Windows...'
                & "$($Context.WinDir)\System32\shutdown.exe" /r /t 0
            }
        }
    }

    Wait-AtlasExit
}

function Invoke-AtlasToggleInProcess {
    <#
    .SYNOPSIS
        Runs one scope of one state in the current process: optional preamble and
        ContextAction, the scoped work, the state record (machine scope only) and the
        reboot or shell-refresh follow-up.
    .DESCRIPTION
        When a state also has user work, the machine scope returns after recording so
        the non-elevated caller can finish with the user scope and the follow-up.
    #>
    param(
        [Parameter(Mandatory = $true)]
        [System.Collections.IDictionary]$Definition,

        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [string]$StateName,

        [Parameter(Mandatory = $true)]
        [ValidateSet('Machine', 'User', 'Local')]
        [string]$Scope,

        [string]$LauncherPath,

        [switch]$Silent,

        [switch]$JustContext,

        [switch]$NoExplorerRestart,

        [ValidateNotNullOrEmpty()]
        [string]$StateRoot = $script:AtlasToggleDefaultStateRoot,

        [switch]$ResetServices,

        [switch]$SkipPreamble,

        [switch]$SkipTitle,

        [switch]$DeferPostAction
    )

    if (-not $Definition['States'].Contains($StateName)) {
        throw "Toggle '$($Definition['Name'])' does not define state '$StateName'."
    }
    $stateEntry = $Definition['States'][$StateName]
    $work = Get-AtlasToggleStateWork -Definition $Definition -StateEntry $stateEntry
    if ($Scope -ceq 'Local' -and -not $work.Local) {
        throw "Toggle '$($Definition['Name'])' is elevated; its state '$StateName' has no local scope."
    }
    if ($Scope -cne 'Local' -and $work.Local) {
        throw "Toggle '$($Definition['Name'])' is not elevated; its state '$StateName' runs locally."
    }

    if (-not $Silent -and -not $SkipPreamble) {
        Show-AtlasTogglePreamble -Definition $Definition -StateEntry $stateEntry `
            -LauncherPath $LauncherPath -JustContext:$JustContext -SkipTitle:$SkipTitle
    }
    $title = Get-AtlasToggleDisplayName -Definition $Definition -StateEntry $stateEntry `
        -LauncherPath $LauncherPath -PreferMenuLabel

    $toggle = New-AtlasToggleContext -Definition $Definition -StateName $StateName `
        -Silent:$Silent -JustContext:$JustContext -NoExplorerRestart:$NoExplorerRestart `
        -ResetServices:$ResetServices -StateRoot $StateRoot -LauncherPath $LauncherPath

    if ($Scope -cne 'User' -and (Test-AtlasToggleStateHasKey -StateEntry $stateEntry -Key 'ContextAction')) {
        Invoke-AtlasToggleFunction -Definition $Definition -FunctionName ([string]$stateEntry['ContextAction']) `
            -Toggle $toggle -Label 'context action'
    }

    if ($JustContext) {
        if (-not $Silent) {
            Write-AtlasCompletion -Title $title
            Wait-AtlasExit
        }
        return
    }

    Invoke-AtlasToggleScopedWork -Definition $Definition -StateEntry $stateEntry -Toggle $toggle -Scope $Scope

    if ($Scope -ceq 'Machine' -and (Test-AtlasToggleRecordsState -Definition $Definition -StateEntry $stateEntry)) {
        Set-AtlasToggleState -Name ([string]$Definition['Name']) -State ([int]$stateEntry['StateValue']) -StateRoot $StateRoot
    }

    Write-AtlasLog -Message "Toggle '$($Definition['Name'])' applied $($Scope.ToLowerInvariant()) state '$StateName'."
    if ($DeferPostAction -or ($Scope -ceq 'Machine' -and $work.User)) {
        return
    }

    Invoke-AtlasTogglePostAction -ToggleName ([string]$Definition['Name']) -StateEntry $stateEntry `
        -Context (Get-AtlasContext) -Silent:$Silent -NoExplorerRestart:$NoExplorerRestart -Title $title
}

function Assert-AtlasToggleMachinePrivilege {
    <#
    .SYNOPSIS
        Requires the privilege a definition's machine work needs in this process.
    #>
    param(
        [Parameter(Mandatory = $true)]
        [System.Collections.IDictionary]$Definition
    )

    switch (Get-AtlasToggleElevation -Definition $Definition) {
        'TrustedInstaller' { Assert-AtlasPrivilege -TrustedInstaller }
        'Admin' { Assert-AtlasPrivilege -Administrator }
        default { throw "Toggle '$($Definition['Name'])' does not declare Admin or TrustedInstaller elevation." }
    }
}

function Invoke-AtlasToggleMachineState {
    <#
    .SYNOPSIS
        Applies and records exactly the machine part of one toggle state from another
        privileged caller: the install plan, a tweak's Toggle entry, or a toggle that
        depends on another toggle's machine state.
    #>
    param(
        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [string]$Name,

        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [string]$State,

        [ValidateNotNullOrEmpty()]
        [string]$StateRoot = $script:AtlasToggleDefaultStateRoot,

        [string]$TogglesRoot
    )

    $definition = Get-AtlasToggleDefinition -Name $Name -TogglesRoot $TogglesRoot
    if (-not $definition['States'].Contains($State)) {
        throw "Toggle '$Name' does not define exact state '$State'."
    }
    Assert-AtlasToggleMachinePrivilege -Definition $definition

    Invoke-AtlasToggleInProcess -Definition $definition -StateName $State -Scope Machine `
        -Silent -NoExplorerRestart -SkipPreamble -StateRoot $StateRoot
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

    $definitionFiles = @(Get-ChildItem -LiteralPath $servicesRoot -File -Filter '*.psd1' |
        Sort-Object -Property Name)
    $expectedNames = @($script:AtlasServiceDefaultResetStates.Keys | ForEach-Object { [string]$_ })
    $actualNames = @($definitionFiles | ForEach-Object { [string]$_.BaseName })
    if ($actualNames.Count -ne $expectedNames.Count) {
        throw 'The shipped service-toggle set does not match the closed ResetServices allowlist.'
    }
    for ($index = 0; $index -lt $expectedNames.Count; $index++) {
        if ($actualNames[$index] -cne $expectedNames[$index]) {
            throw 'The shipped service-toggle set does not match the closed ResetServices allowlist.'
        }
    }

    $completed = @{}
    foreach ($name in $expectedNames) {
        if ($name -ceq 'NetworkDiscovery' -and -not $completed.ContainsKey('LanmanWorkstation')) {
            throw 'ResetServices cannot skip the NetworkDiscovery dependency before LanmanWorkstation completes.'
        }

        $definition = Get-AtlasToggleDefinition -Name $name -TogglesRoot $servicesRoot
        if ((Get-AtlasToggleElevation -Definition $definition) -cne 'Admin') {
            throw "ResetServices definition '$name' must remain an exact Administrator toggle."
        }

        $defaultStates = @($definition['States'].Keys | Where-Object {
                $stateEntry = $definition['States'][$_]
                $stateEntry.Contains('Launcher') -and
                    ([string]$stateEntry['Launcher']).IndexOf('(default)', [StringComparison]::OrdinalIgnoreCase) -ge 0
            })
        $expectedState = [string]$script:AtlasServiceDefaultResetStates[$name]
        if ($defaultStates.Count -ne 1 -or [string]$defaultStates[0] -cne $expectedState) {
            throw "ResetServices definition '$name' must declare only '$expectedState' as its '(default)' state."
        }

        Invoke-AtlasToggleInProcess -Definition $definition -StateName $expectedState -Scope Machine `
            -Silent -NoExplorerRestart -SkipPreamble -ResetServices
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
        [string]$Operation = 'ExplorerRefresh',

        [switch]$Silent
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

    $helperPath = [IO.Path]::Combine($modulesPath, 'Scripts', 'Operations', 'Invoke-AtlasUserShellRefresh.ps1')
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
    if (-not $Silent) {
        Write-AtlasRestartNotice -Kind ExplorerRestarted
    }
}

function Invoke-AtlasToggle {
    <#
    .SYNOPSIS
        Applies a toggle state: resolves the definition, runs its machine work under
        the declared elevation (relaunching through UAC or the TrustedInstaller broker
        when needed), records the state only after that work completes, runs its user
        work in the launching user's own process, and handles the reboot or
        Explorer-refresh follow-up.
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

        # An enclosing interactive action owns completion for a nested user-only
        # choice. Elevation, caller validation and recording still run normally.
        [switch]$DeferPostAction,

        [ValidateNotNullOrEmpty()]
        [string]$StateRoot = $script:AtlasToggleDefaultStateRoot,

        # Set by the engine on the privileged child it launches for a state that also
        # has user work: apply and record only the machine part.
        [switch]$MachineOnly
    )

    $definition = Get-AtlasToggleDefinition -Name $Name -TogglesRoot $TogglesRoot

    # A nested choice reports into the enclosing run's outcome; every other call is a
    # new run.
    if (-not $DeferPostAction) {
        Reset-AtlasRunOutcome
    }

    # A Menu toggle asks before its state is known, so the heading comes first and the
    # preamble later skips it.
    $titleShown = $false
    if (-not $Silent -and -not $State -and $definition.Contains('Menu') -and [bool]$definition['Menu']) {
        Write-AtlasTitle -Text (Get-AtlasToggleDisplayName -Definition $definition -StateEntry @{} -LauncherPath $LauncherPath)
        $titleShown = $true
    }

    $stateName = Resolve-AtlasToggleStateName -Definition $definition -State $State -Silent:$Silent -StateRoot $StateRoot
    $stateEntry = $definition['States'][$stateName]
    $elevation = Get-AtlasToggleElevation -Definition $definition
    $work = Get-AtlasToggleStateWork -Definition $definition -StateEntry $stateEntry
    $title = Get-AtlasToggleDisplayName -Definition $definition -StateEntry $stateEntry -LauncherPath $LauncherPath -PreferMenuLabel

    if ($DeferPostAction -and (-not $work.User -or $work.Machine -or $work.ProtectedUserRegistry -or
        $JustContext -or $MachineOnly -or
        (Test-AtlasToggleStateHasKey -StateEntry $stateEntry -Key 'ContextAction') -or
        ($stateEntry.Contains('Reboot') -and [string]$stateEntry['Reboot'] -cne 'None'))) {
        throw 'Deferring completion is supported only for a user-only choice with no reboot or context action.'
    }

    $isTrustedInstaller = Test-AtlasTrustedInstaller
    $isSystem = Test-AtlasSystem
    $isAdmin = Test-AtlasAdmin
    if ($isTrustedInstaller -and $elevation -cne 'TrustedInstaller') {
        throw "Toggle '$Name' does not declare exact TrustedInstaller elevation."
    }

    $inProcess = @{
        Definition   = $definition
        StateName    = $stateName
        LauncherPath = $LauncherPath
        Silent       = $Silent
        StateRoot    = $StateRoot
        SkipTitle    = $titleShown
    }

    # First sign-in replay runs in the new account's own process: only user work applies.
    if ($env:ATLAS_USER_CONTEXT -ceq '1') {
        if ($work.User) {
            Invoke-AtlasToggleInProcess @inProcess -Scope User -SkipPreamble `
                -NoExplorerRestart:$NoExplorerRestart -DeferPostAction:$DeferPostAction
        }
        else {
            Write-AtlasLog -Message "Toggle '$Name' state '$stateName' has no per-user work to replay."
        }
        return
    }

    if ($elevation -ceq 'None') {
        Invoke-AtlasToggleInProcess @inProcess -Scope Local -JustContext:$JustContext `
            -NoExplorerRestart:$NoExplorerRestart
        return
    }

    $deferShellRefreshToCaller = -not $NoExplorerRestart -and -not $JustContext -and
        $stateEntry.Contains('Reboot') -and [string]$stateEntry['Reboot'] -ceq 'RestartExplorer'
    $shellRefreshOperation = 'ExplorerRefresh'
    if ($stateEntry.Contains('ShellRefreshOperation')) {
        $shellRefreshOperation = [string]$stateEntry['ShellRefreshOperation']
    }

    if ($MachineOnly) {
        # We are the privileged child of a state that also has user work.
        if (-not $work.User) {
            throw "Toggle '$Name' state '$stateName' has no user work, so -MachineOnly does not apply."
        }
        if ($JustContext) {
            throw "Toggle '$Name' cannot combine -MachineOnly with a context-only invocation."
        }
        if ($elevation -ceq 'TrustedInstaller' -and -not $isTrustedInstaller) {
            if ($isSystem) {
                throw "Toggle '$Name' is running as LocalSystem without strict TrustedInstaller token evidence."
            }
            if (-not $isAdmin) {
                throw "Toggle '$Name' machine work requires an already elevated Administrator child."
            }
            Invoke-AtlasTrustedInstaller -Operation Toggle -Name ([string]$definition['Name']) -State $stateName `
                -Silent:$true -NoExplorerRestart:$true -MachineOnly | Out-Null
            return
        }
        if ($elevation -ceq 'Admin' -and -not $isAdmin) {
            throw "Toggle '$Name' machine work requires an already elevated Administrator child."
        }
        if (-not $Silent) {
            # This window belongs to the run the user started elsewhere; it closes on its
            # own, so it gets a heading but no warning gate, closing line or pause.
            Write-AtlasTitle -Text $title -Explanation 'Administrator step for the change started in the other window.'
        }
        Invoke-AtlasToggleInProcess @inProcess -Scope Machine -NoExplorerRestart -SkipPreamble
        return
    }

    if ($work.User) {
        # The user part must run under the launching user's own medium token, so the
        # machine part goes to a privileged child and this process finishes afterward.
        if ($isTrustedInstaller -or $isSystem -or $isAdmin) {
            throw "Toggle '$Name' has per-user work and must be launched from a non-elevated user process so that work cannot inherit an elevated token."
        }
        $binding = Get-AtlasToggleUserCallerBinding
        if (-not $Silent) {
            Show-AtlasTogglePreamble -Definition $definition -StateEntry $stateEntry `
                -LauncherPath $LauncherPath -JustContext:$JustContext -SkipTitle:$titleShown
        }

        if ($Silent) {
            throw "Toggle '$Name' requires elevation for its machine work; refusing to prompt for elevation in silent mode."
        }
        # A user-only state has no privileged prerequisite. Complete its work before
        # asking the existing machine child to record the choice. Otherwise a failed
        # app registration can replace a previously applied Disable with Enable.
        # Protected user policies and context actions still need the original order.
        $userBeforeRecord = -not $JustContext -and -not $work.Machine -and
            -not $work.ProtectedUserRegistry -and
            -not (Test-AtlasToggleStateHasKey -StateEntry $stateEntry -Key 'ContextAction')
        if ($userBeforeRecord) {
            Invoke-AtlasToggleInProcess @inProcess -Scope User -SkipPreamble -NoExplorerRestart -DeferPostAction
            $actualBinding = Get-AtlasToggleUserCallerBinding
            if ([string]$actualBinding.Sid -cne [string]$binding.Sid -or
                [int]$actualBinding.SessionId -ne [int]$binding.SessionId) {
                throw 'The toggle caller identity or Windows session changed before recording the user choice.'
            }
        }
        # An Administrator child remains interactive for prerequisite questions.
        # MachineOnly already suppresses its duplicate preamble and final pause.
        # The TrustedInstaller broker remains noninteractive by design.
        $argumentList = Get-AtlasToggleRelaunchArgumentList -Name $Name -State $stateName -LauncherPath $LauncherPath `
            -Silent:($elevation -ceq 'TrustedInstaller') -JustContext:$JustContext -NoExplorerRestart -MachineOnly
        Invoke-AtlasToggleElevatedChild -Name $Name -ArgumentList $argumentList -Silent:$Silent

        $actualBinding = Get-AtlasToggleUserCallerBinding
        if ([string]$actualBinding.Sid -cne [string]$binding.Sid -or
            [int]$actualBinding.SessionId -ne [int]$binding.SessionId) {
            throw 'The toggle caller identity or Windows session changed across the privileged machine work.'
        }
        if ($userBeforeRecord) {
            if (-not $DeferPostAction) {
                Invoke-AtlasTogglePostAction -ToggleName ([string]$definition['Name']) -StateEntry $stateEntry `
                    -Context (Get-AtlasContext) -Silent:$Silent -NoExplorerRestart:$NoExplorerRestart -Title $title
            }
        }
        else {
            Invoke-AtlasToggleInProcess @inProcess -Scope User -SkipPreamble -NoExplorerRestart:$NoExplorerRestart
        }
        return
    }

    # Machine-only work.
    $sufficientlyPrivileged = ($elevation -ceq 'Admin' -and $isAdmin) -or
        ($elevation -ceq 'TrustedInstaller' -and $isTrustedInstaller)
    if ($sufficientlyPrivileged) {
        Invoke-AtlasToggleInProcess @inProcess -Scope Machine -JustContext:$JustContext `
            -NoExplorerRestart:$NoExplorerRestart
        return
    }

    if ($elevation -ceq 'TrustedInstaller' -and $isSystem) {
        throw "Toggle '$Name' is running as LocalSystem without strict TrustedInstaller token evidence."
    }

    if ($elevation -ceq 'TrustedInstaller' -and $isAdmin) {
        if (-not $Silent) {
            Show-AtlasTogglePreamble -Definition $definition -StateEntry $stateEntry `
                -LauncherPath $LauncherPath -JustContext:$JustContext -SkipTitle:$titleShown
        }
        if (-not $Silent -and -not $JustContext -and $stateEntry.Contains('InteractiveState')) {
            $selectionContext = New-AtlasToggleContext -Definition $definition -StateName $stateName `
                -StateRoot $StateRoot -LauncherPath $LauncherPath
            $selection = @(Invoke-AtlasToggleFunction -Definition $definition `
                -FunctionName ([string]$stateEntry['InteractiveState']) -Toggle $selectionContext -Label 'interactive choice')
            if ($selection.Count -ne 1 -or $selection[0] -isnot [string] -or
                -not $definition['States'].Contains([string]$selection[0])) {
                throw "Toggle '$Name' interactive choice must return exactly one installed state name."
            }
            $selectedWork = Get-AtlasToggleStateWork -Definition $definition -StateEntry $definition['States'][[string]$selection[0]]
            if ($selectedWork.User -or $selectedWork.Local) {
                throw "Toggle '$Name' interactive choice must select machine-only work."
            }
            $stateName = [string]$selection[0]
        }
        Invoke-AtlasTrustedInstaller -Operation Toggle -Name ([string]$definition['Name']) -State $stateName `
            -Silent:$true -JustContext:$JustContext `
            -NoExplorerRestart:($NoExplorerRestart -or $deferShellRefreshToCaller) | Out-Null
        if ($JustContext) {
            if (-not $Silent) {
                Write-AtlasCompletion -Title $title
                Wait-AtlasExit
            }
            return
        }
        Invoke-AtlasTogglePostAction -ToggleName ([string]$definition['Name']) -StateEntry $stateEntry `
            -Context (Get-AtlasContext) -Silent:$Silent -NoExplorerRestart:$NoExplorerRestart -Title $title
        return
    }

    # Not elevated at all: relaunch this invocation through UAC. A TrustedInstaller
    # toggle then reaches the broker from that Administrator child.
    if ($Silent) {
        $privilegeText = if ($elevation -ceq 'Admin') { 'Administrator rights' } else { 'TrustedInstaller elevation' }
        throw "Toggle '$Name' requires $privilegeText; refusing to prompt for elevation in silent mode."
    }
    if (-not $Silent -and -not $titleShown) {
        # The elevated window owns the rest of the run; this one only shows what it is
        # waiting for.
        Write-AtlasTitle -Text $title
    }
    $argumentList = Get-AtlasToggleRelaunchArgumentList -Name $Name -State $stateName -LauncherPath $LauncherPath `
        -Silent:$Silent -JustContext:$JustContext `
        -NoExplorerRestart:($NoExplorerRestart -or $deferShellRefreshToCaller)
    Invoke-AtlasToggleElevatedChild -Name $Name -ArgumentList $argumentList -Silent:$Silent
    if ($deferShellRefreshToCaller) {
        if (-not $Silent) {
            Write-AtlasStep -Text 'Restarting File Explorer...'
        }
        Invoke-AtlasToggleCurrentSessionShellRefresh -Operation $shellRefreshOperation -Silent:$Silent
    }
}
