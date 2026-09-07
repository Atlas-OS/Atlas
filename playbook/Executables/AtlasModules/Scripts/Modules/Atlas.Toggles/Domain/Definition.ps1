# Atlas.Toggles domain: definition loading, normalization and validation.
#
# A toggle is one data-only definition, AtlasModules\Toggles\<Group>\<Name>.psd1, plus an
# optional companion script beside it that contains only functions. Definitions are
# loaded with the restricted data-file parser, so no toggle code runs until the engine
# invokes a named companion function. See AtlasModules\Toggles\README.md for the schema.
#
# Each state declares its work with the same declarative vocabulary as install tweaks
# (Registry, Services, ScheduledTasks) plus named companion functions. The engine derives
# where that work runs from the declarations themselves:
#
#   Machine work  HKLM registry entries, Services, ScheduledTasks, MachineAction
#                 Runs under the declared elevation (Administrator or TrustedInstaller)
#                 and is what upgrade replay re-applies.
#   User work     HKCU registry entries, UserAction
#                 Runs in the launching user's own non-elevated process and is replayed
#                 for each account at first sign-in.
#   Local work    Registry entries and Action of an Elevation = 'None' toggle
#                 Runs in the launcher process as-is and records no state.

$script:AtlasToggleTopLevelKeys = @(
    'Name', 'Description', 'Elevation', 'Warning', 'Menu', 'Launcher', 'ToolboxLauncher',
    'SilentDefault', 'NoStateRecord', 'Script', 'States'
)
$script:AtlasToggleStateKeys = @(
    'Name', 'StateValue', 'Launcher', 'ToolboxLauncher', 'MenuLabel', 'Reboot',
    'ShellRefreshOperation', 'NoStateRecord', 'Registry', 'Services', 'ScheduledTasks',
    'MachineAction', 'UserAction', 'Action', 'ContextAction', 'ReplayApplicable', 'InteractiveState', 'Internal'
)
$script:AtlasToggleFunctionKeys = @(
    'MachineAction', 'UserAction', 'Action', 'ContextAction', 'ReplayApplicable', 'InteractiveState'
)
$script:AtlasToggleElevations = @('None', 'Admin', 'TrustedInstaller')
$script:AtlasToggleRebootModes = @('None', 'Recommend', 'Prompt', 'RestartExplorer')
$script:AtlasToggleShellRefreshOperations = @(
    'ShellRefresh', 'ExplorerRefresh', 'SearchShellRefresh', 'ExplorerAndSettingsRefresh'
)
$script:AtlasToggleEntryKeys = @{
    Registry       = @('Path', 'Name', 'Type', 'Data', 'Operation', 'Arch', 'IgnoreErrors', 'AllowOsProtected', 'SkipVerification', 'UseGroupPolicy', 'Mask')
    Services       = @('Name', 'Operation', 'StartupType', 'AllowMissing', 'IgnoreErrors')
    ScheduledTasks = @('Path', 'Operation', 'IgnoreErrors')
}
$script:AtlasToggleIdentifierPattern = '\A[A-Za-z][A-Za-z0-9]*\z'
$script:AtlasToggleFunctionPattern = '\A[A-Z][A-Za-z]+-Atlas[A-Za-z0-9]+\z'

function Get-AtlasToggleRoot {
    param(
        [string]$TogglesRoot
    )

    if ($TogglesRoot) {
        return $TogglesRoot
    }

    return Join-Path -Path (Get-AtlasContext).AtlasModulesPath -ChildPath 'Toggles'
}

function Find-AtlasToggleDefinitionFile {
    <#
    .SYNOPSIS
        Returns the single definition file for a toggle name beneath the toggles root.
    #>
    param(
        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [string]$Name,

        [string]$TogglesRoot
    )

    if ($Name -cnotmatch $script:AtlasToggleIdentifierPattern) {
        throw "Toggle name '$Name' is not a valid identifier."
    }

    $root = Get-AtlasToggleRoot -TogglesRoot $TogglesRoot
    if (-not (Test-Path -LiteralPath $root -PathType Container)) {
        throw "Toggle definitions root '$root' does not exist."
    }

    $files = @(Get-ChildItem -LiteralPath $root -Recurse -File -Filter "$Name.psd1" -ErrorAction Stop |
        Where-Object { $_.BaseName -ceq $Name })
    if ($files.Count -eq 0) {
        throw "No toggle definition named '$Name' was found under '$root'."
    }
    if ($files.Count -gt 1) {
        throw "Multiple toggle definitions named '$Name' were found under '$root': $(($files | ForEach-Object { $_.FullName }) -join ', ')."
    }

    return $files[0].FullName
}

function Get-AtlasToggleCompanionFunctionNames {
    <#
    .SYNOPSIS
        Parses a companion script without executing it and returns the names of the
        functions it defines. Throws when the file contains anything other than
        function definitions, so a companion can never carry top-level side effects.
    #>
    param(
        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [string]$Path
    )

    $tokens = $null
    $parseErrors = $null
    $ast = [System.Management.Automation.Language.Parser]::ParseFile($Path, [ref]$tokens, [ref]$parseErrors)
    if ($parseErrors -and $parseErrors.Count -gt 0) {
        throw "Companion script '$Path' does not parse: $($parseErrors[0].Message)"
    }
    if ($null -ne $ast.ParamBlock -or $null -ne $ast.BeginBlock -or $null -ne $ast.ProcessBlock -or
        $null -ne $ast.DynamicParamBlock) {
        throw "Companion script '$Path' must contain only function definitions."
    }

    $names = @()
    foreach ($statement in @($ast.EndBlock.Statements)) {
        if ($statement -isnot [System.Management.Automation.Language.FunctionDefinitionAst]) {
            throw "Companion script '$Path' must contain only function definitions; found '$($statement.Extent.Text.Split("`n")[0].Trim())' at line $($statement.Extent.StartLineNumber)."
        }
        $names += [string]$statement.Name
    }

    return $names
}

function ConvertTo-AtlasToggleDefinition {
    <#
    .SYNOPSIS
        Normalizes raw data-file content into the in-memory definition the engine uses:
        an ordered dictionary of states keyed by state name, plus SourcePath, ScriptPath
        and the parsed companion function list.
    #>
    param(
        [Parameter(Mandatory = $true)]
        [AllowNull()]
        [object]$Data,

        [Parameter(Mandatory = $true)]
        [string]$SourcePath
    )

    if ($Data -isnot [System.Collections.IDictionary]) {
        throw "Toggle definition '$SourcePath' is not a hashtable."
    }

    $definition = [ordered]@{}
    foreach ($key in @($Data.Keys)) {
        if ([string]$key -ceq 'States') {
            continue
        }
        $definition[[string]$key] = $Data[$key]
    }

    $states = [ordered]@{}
    foreach ($state in @($Data['States'])) {
        if ($state -isnot [System.Collections.IDictionary] -or -not $state.Contains('Name')) {
            throw "Toggle definition '$SourcePath' has a state without a Name."
        }
        $stateName = [string]$state['Name']
        if ($states.Contains($stateName)) {
            throw "Toggle definition '$SourcePath' declares state '$stateName' more than once."
        }
        $entry = [ordered]@{}
        foreach ($key in @($state.Keys)) {
            $entry[[string]$key] = $state[$key]
        }
        $states[$stateName] = $entry
    }
    $definition['States'] = $states
    $definition['SourcePath'] = $SourcePath

    $scriptPath = $null
    $functions = @()
    if ($Data.Contains('Script') -and -not [string]::IsNullOrWhiteSpace([string]$Data['Script'])) {
        $scriptPath = [IO.Path]::Combine((Split-Path -Path $SourcePath -Parent), [string]$Data['Script'])
        if (Test-Path -LiteralPath $scriptPath -PathType Leaf) {
            $functions = @(Get-AtlasToggleCompanionFunctionNames -Path $scriptPath)
        }
    }
    $definition['ScriptPath'] = $scriptPath
    $definition['Functions'] = $functions

    return $definition
}

function Test-AtlasToggleStateHasKey {
    param(
        [Parameter(Mandatory = $true)]
        [System.Collections.IDictionary]$StateEntry,

        [Parameter(Mandatory = $true)]
        [string]$Key
    )

    return $StateEntry.Contains($Key) -and $null -ne $StateEntry[$Key] -and
        -not ($StateEntry[$Key] -is [string] -and [string]::IsNullOrWhiteSpace([string]$StateEntry[$Key])) -and
        -not ($StateEntry[$Key] -is [array] -and $StateEntry[$Key].Count -eq 0)
}

function Get-AtlasToggleStateWork {
    <#
    .SYNOPSIS
        Classifies where a state's declared work runs. Returns an object with Machine,
        User and Local booleans; exactly the machine part is recorded and replayed under
        TrustedInstaller, and exactly the user part is replayed per account.
    #>
    param(
        [Parameter(Mandatory = $true)]
        [System.Collections.IDictionary]$Definition,

        [Parameter(Mandatory = $true)]
        [System.Collections.IDictionary]$StateEntry
    )

    $elevation = Get-AtlasToggleElevation -Definition $Definition
    $machineRegistry = $false
    $userRegistry = $false
    $protectedUserRegistry = $false
    if (Test-AtlasToggleStateHasKey -StateEntry $StateEntry -Key 'Registry') {
        foreach ($entry in @($StateEntry['Registry'])) {
            if ($entry -isnot [System.Collections.IDictionary] -or -not $entry.Contains('Path')) {
                continue
            }
            switch (Get-AtlasRegistryEntryTargetScope -Path ([string]$entry['Path'])) {
                'Machine' { $machineRegistry = $true }
                'CurrentUser' { $userRegistry = $true }
                'ProtectedCurrentUser' { $protectedUserRegistry = $true }
                default { throw "Toggle '$($Definition.Name)' registry entry '$($entry['Path'])' targets an unsupported hive." }
            }
        }
    }

    if ($elevation -ceq 'None') {
        return [pscustomobject]@{
            Machine               = $false
            User                  = $false
            Local                 = $machineRegistry -or $userRegistry -or
                (Test-AtlasToggleStateHasKey -StateEntry $StateEntry -Key 'Action')
            MachineRegistry       = $machineRegistry
            UserRegistry          = $userRegistry
            ProtectedUserRegistry = $protectedUserRegistry
        }
    }

    return [pscustomobject]@{
        Machine               = $machineRegistry -or
            (Test-AtlasToggleStateHasKey -StateEntry $StateEntry -Key 'Services') -or
            (Test-AtlasToggleStateHasKey -StateEntry $StateEntry -Key 'ScheduledTasks') -or
            (Test-AtlasToggleStateHasKey -StateEntry $StateEntry -Key 'MachineAction')
        User                  = $userRegistry -or
            (Test-AtlasToggleStateHasKey -StateEntry $StateEntry -Key 'UserAction')
        Local                 = $false
        MachineRegistry       = $machineRegistry
        UserRegistry          = $userRegistry
        ProtectedUserRegistry = $protectedUserRegistry
    }
}

function Get-AtlasToggleElevation {
    param(
        [Parameter(Mandatory = $true)]
        [System.Collections.IDictionary]$Definition
    )

    if ($Definition.Contains('Elevation') -and -not [string]::IsNullOrWhiteSpace([string]$Definition['Elevation'])) {
        return [string]$Definition['Elevation']
    }
    return 'None'
}

function Test-AtlasToggleRecordsState {
    param(
        [Parameter(Mandatory = $true)]
        [System.Collections.IDictionary]$Definition,

        [Parameter(Mandatory = $true)]
        [System.Collections.IDictionary]$StateEntry
    )

    if ($Definition.Contains('NoStateRecord') -and [bool]$Definition['NoStateRecord']) {
        return $false
    }
    if ($StateEntry.Contains('NoStateRecord') -and [bool]$StateEntry['NoStateRecord']) {
        return $false
    }
    return $true
}

function Get-AtlasToggleDefinitionProblems {
    <#
    .SYNOPSIS
        Validates one normalized definition and returns a list of problem strings;
        an empty list means the definition is well formed.
    #>
    param(
        [Parameter(Mandatory = $true)]
        [System.Collections.IDictionary]$Definition,

        [Parameter(Mandatory = $true)]
        [string]$ExpectedName
    )

    $problems = New-Object System.Collections.Generic.List[string]

    foreach ($key in @($Definition.Keys)) {
        if ([string]$key -in @('SourcePath', 'ScriptPath', 'Functions')) {
            continue
        }
        if ($script:AtlasToggleTopLevelKeys -cnotcontains [string]$key) {
            $problems.Add("unknown top-level key '$key'; valid keys: $($script:AtlasToggleTopLevelKeys -join ', ').")
        }
    }

    $name = if ($Definition.Contains('Name')) { [string]$Definition['Name'] } else { '' }
    if ([string]::IsNullOrWhiteSpace($name)) {
        $problems.Add("missing the required 'Name' key.")
    }
    elseif ($name -cne $ExpectedName) {
        $problems.Add("declares Name '$name' but its file name requires '$ExpectedName'.")
    }

    $elevation = Get-AtlasToggleElevation -Definition $Definition
    if ($script:AtlasToggleElevations -cnotcontains $elevation) {
        $problems.Add("has an invalid Elevation '$elevation'; valid values: $($script:AtlasToggleElevations -join ', ').")
    }

    foreach ($stringKey in @('Description', 'Warning', 'Launcher', 'ToolboxLauncher', 'SilentDefault', 'Script')) {
        if ($Definition.Contains($stringKey) -and $Definition[$stringKey] -isnot [string]) {
            $problems.Add("'$stringKey' must be a string.")
        }
    }
    foreach ($boolKey in @('Menu', 'NoStateRecord')) {
        if ($Definition.Contains($boolKey) -and $Definition[$boolKey] -isnot [bool]) {
            $problems.Add("'$boolKey' must be `$true or `$false.")
        }
    }

    $isMenu = $Definition.Contains('Menu') -and [bool]$Definition['Menu']
    $hasTopLauncher = $Definition.Contains('Launcher') -and -not [string]::IsNullOrWhiteSpace([string]$Definition['Launcher'])
    if ($isMenu -and -not $hasTopLauncher) {
        $problems.Add("is a Menu toggle and must declare a top-level 'Launcher'.")
    }
    if (-not $isMenu -and $hasTopLauncher) {
        $problems.Add("declares a top-level 'Launcher' but only Menu toggles use one; put launchers on states.")
    }
    if ($Definition.Contains('SilentDefault') -and -not $isMenu) {
        $problems.Add("declares 'SilentDefault' but is not a Menu toggle.")
    }

    if ($Definition.Contains('Script')) {
        $scriptName = [string]$Definition['Script']
        if ($scriptName -cne "$ExpectedName.ps1") {
            $problems.Add("'Script' must be '$ExpectedName.ps1' beside the definition.")
        }
        elseif (-not [string]::IsNullOrWhiteSpace([string]$Definition['ScriptPath']) -and
            -not (Test-Path -LiteralPath ([string]$Definition['ScriptPath']) -PathType Leaf)) {
            $problems.Add("companion script '$($Definition['ScriptPath'])' is missing.")
        }
    }
    $functions = @($Definition['Functions'])
    $referencedFunctions = @()

    $states = $Definition['States']
    if ($null -eq $states -or $states.Count -eq 0) {
        $problems.Add("declares no States.")
        $states = [ordered]@{}
    }
    if ($Definition.Contains('SilentDefault') -and -not $states.Contains([string]$Definition['SilentDefault'])) {
        $problems.Add("'SilentDefault' names an unknown state '$($Definition['SilentDefault'])'.")
    }

    $stateValues = @{}
    foreach ($stateName in @($states.Keys)) {
        $state = $states[$stateName]
        $label = "state '$stateName'"
        if ([string]$stateName -cnotmatch $script:AtlasToggleIdentifierPattern) {
            $problems.Add("$label is not a valid identifier.")
        }
        foreach ($key in @($state.Keys)) {
            if ($script:AtlasToggleStateKeys -cnotcontains [string]$key) {
                $problems.Add("$label has an unknown key '$key'; valid keys: $($script:AtlasToggleStateKeys -join ', ').")
            }
        }

        $recordsState = Test-AtlasToggleRecordsState -Definition $Definition -StateEntry $state
        if ($recordsState) {
            if (-not $state.Contains('StateValue') -or $state['StateValue'] -isnot [int]) {
                $problems.Add("$label needs an integer StateValue or NoStateRecord.")
            }
            elseif ($stateValues.ContainsKey([int]$state['StateValue'])) {
                $problems.Add("$label reuses StateValue $($state['StateValue']) of state '$($stateValues[[int]$state['StateValue']])'.")
            }
            else {
                $stateValues[[int]$state['StateValue']] = $stateName
            }
        }

        if ($isMenu) {
            if ($state.Contains('Launcher')) {
                $problems.Add("$label declares a Launcher, but Menu toggles use the top-level launcher.")
            }
        }
        elseif (-not ($state.Contains('Internal') -and $state['Internal'] -eq $true) -and
            (-not $state.Contains('Launcher') -or [string]::IsNullOrWhiteSpace([string]$state['Launcher']))) {
            $problems.Add("$label has no Launcher.")
        }
        if ($state.Contains('Internal')) {
            if ($state['Internal'] -isnot [bool] -or -not $state['Internal'] -or
                $state.Contains('Launcher') -or $state.Contains('ToolboxLauncher') -or $recordsState -or $isMenu) {
                $problems.Add("$label Internal must be true, have no launcher, and declare NoStateRecord.")
            }
        }
        if ($state.Contains('InteractiveState') -and
            ($elevation -cne 'TrustedInstaller' -or $state.Contains('UserAction') -or $state.Contains('Internal'))) {
            $problems.Add("$label InteractiveState requires a public TrustedInstaller machine state.")
        }

        if ($state.Contains('Reboot') -and $script:AtlasToggleRebootModes -cnotcontains [string]$state['Reboot']) {
            $problems.Add("$label has an invalid Reboot '$($state['Reboot'])'; valid values: $($script:AtlasToggleRebootModes -join ', ').")
        }
        if ($state.Contains('ShellRefreshOperation')) {
            if ($script:AtlasToggleShellRefreshOperations -cnotcontains [string]$state['ShellRefreshOperation']) {
                $problems.Add("$label has an invalid ShellRefreshOperation '$($state['ShellRefreshOperation'])'.")
            }
            if (-not $state.Contains('Reboot') -or [string]$state['Reboot'] -cne 'RestartExplorer') {
                $problems.Add("$label declares ShellRefreshOperation without Reboot = 'RestartExplorer'.")
            }
        }

        foreach ($entryKey in @('Registry', 'Services', 'ScheduledTasks')) {
            if (-not $state.Contains($entryKey)) {
                continue
            }
            foreach ($entry in @($state[$entryKey])) {
                if ($entry -isnot [System.Collections.IDictionary]) {
                    $problems.Add("$label '$entryKey' entries must be hashtables.")
                    continue
                }
                foreach ($key in @($entry.Keys)) {
                    if ($script:AtlasToggleEntryKeys[$entryKey] -cnotcontains [string]$key) {
                        $problems.Add("$label $entryKey entry has an unknown key '$key'.")
                    }
                }
                if ($entryKey -ceq 'Registry' -and $entry.Contains('UseGroupPolicy')) {
                    if ($entry['UseGroupPolicy'] -isnot [bool]) {
                        $problems.Add("$label Registry entry 'UseGroupPolicy' must be a boolean.")
                    }
                    elseif ($entry['UseGroupPolicy'] -and (
                            ($entry.Contains('Operation') -and $entry['Operation'] -ine 'Set') -or
                            $entry['Type'] -ine 'DWord' -or
                            $entry['Path'] -notmatch '^(HKLM:?|HKEY_LOCAL_MACHINE|Registry::HKEY_LOCAL_MACHINE)\\SOFTWARE\\Policies\\')) {
                        $problems.Add("$label UseGroupPolicy requires an HKLM Software\Policies DWord Set entry.")
                    }
                }
                if ($entryKey -ceq 'Registry' -and $entry.Contains('SkipVerification') -and
                    ($entry['SkipVerification'] -isnot [string] -or [string]::IsNullOrWhiteSpace($entry['SkipVerification']))) {
                    $problems.Add("$label Registry entry 'SkipVerification' must be a non-empty reason string.")
                }
            }
        }

        foreach ($functionKey in $script:AtlasToggleFunctionKeys) {
            if (-not $state.Contains($functionKey)) {
                continue
            }
            $functionName = $state[$functionKey]
            if ($functionName -isnot [string] -or $functionName -cnotmatch $script:AtlasToggleFunctionPattern) {
                $problems.Add("$label '$functionKey' must name a Verb-AtlasNoun function in the companion script.")
                continue
            }
            $referencedFunctions += [string]$functionName
            if ($functions -cnotcontains [string]$functionName) {
                $problems.Add("$label '$functionKey' names '$functionName', which the companion script does not define.")
            }
        }

        try {
            $work = Get-AtlasToggleStateWork -Definition $Definition -StateEntry $state
        }
        catch {
            $problems.Add("$label $($_.Exception.Message)")
            continue
        }
        if ($work.ProtectedUserRegistry) {
            $problems.Add("$label writes a protected HKCU policy path; toggles may not set user policy from a medium-integrity process.")
        }
        if ($state.Contains('InteractiveState') -and ($work.User -or $work.Local)) {
            $problems.Add("$label InteractiveState cannot select work for another user or local context.")
        }
        if ($elevation -ceq 'None') {
            foreach ($key in @('Services', 'ScheduledTasks', 'MachineAction', 'UserAction', 'ReplayApplicable')) {
                if ($state.Contains($key)) {
                    $problems.Add("$label declares '$key', which requires Admin or TrustedInstaller elevation.")
                }
            }
            if ($work.MachineRegistry) {
                $problems.Add("$label writes machine registry paths without elevation.")
            }
            if ($recordsState) {
                $problems.Add("$label records state, but an unelevated toggle cannot write the protected state store; declare NoStateRecord.")
            }
            if (-not $work.Local) {
                $problems.Add("$label declares no work.")
            }
        }
        else {
            if ($state.Contains('Action')) {
                $problems.Add("$label declares 'Action'; elevated toggles declare MachineAction and/or UserAction so each part runs in its own context.")
            }
            if (-not $work.Machine -and -not $work.User) {
                $problems.Add("$label declares no work.")
            }
        }
    }

    foreach ($functionName in $functions) {
        if ($functionName -cnotmatch $script:AtlasToggleFunctionPattern) {
            $problems.Add("companion function '$functionName' must be named Verb-AtlasNoun.")
        }
    }
    if ($referencedFunctions.Count -gt 0 -and [string]::IsNullOrWhiteSpace([string]$Definition['ScriptPath'])) {
        $problems.Add("references companion functions but declares no 'Script'.")
    }

    return $problems
}

function Import-AtlasToggleDefinitionFile {
    <#
    .SYNOPSIS
        Loads, normalizes and validates one definition file; throws on the first problem.
    #>
    param(
        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [string]$Path
    )

    $expectedName = [IO.Path]::GetFileNameWithoutExtension($Path)
    $data = Import-AtlasDataFile -LiteralPath $Path
    $definition = ConvertTo-AtlasToggleDefinition -Data $data -SourcePath $Path
    $problems = @(Get-AtlasToggleDefinitionProblems -Definition $definition -ExpectedName $expectedName)
    if ($problems.Count -gt 0) {
        throw "Toggle definition '$Path' $($problems[0])"
    }

    return $definition
}

function Get-AtlasToggleDefinition {
    <#
    .SYNOPSIS
        Locates, loads and validates a toggle definition by name from
        <TogglesRoot>\<Group>\<Name>.psd1.
    #>
    param(
        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [string]$Name,

        [string]$TogglesRoot
    )

    $path = Find-AtlasToggleDefinitionFile -Name $Name -TogglesRoot $TogglesRoot
    return Import-AtlasToggleDefinitionFile -Path $path
}

function Test-AtlasToggleDefinition {
    <#
    .SYNOPSIS
        Validates every toggle definition beneath a path (or one file) without running
        any toggle code. Returns one object per problem; an empty result means all
        definitions are well formed. Used by CI and the launcher generator.
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [string]$Path
    )

    $files = if (Test-Path -LiteralPath $Path -PathType Leaf) {
        @(Get-Item -LiteralPath $Path)
    }
    else {
        @(Get-ChildItem -LiteralPath $Path -Recurse -File -Filter '*.psd1' | Sort-Object -Property FullName)
    }

    $results = @()
    $seenNames = @{}
    foreach ($file in $files) {
        $expectedName = $file.BaseName
        if ($seenNames.ContainsKey($expectedName)) {
            $results += [pscustomobject]@{ Path = $file.FullName; Problem = "duplicates toggle '$expectedName' at '$($seenNames[$expectedName])'." }
        }
        $seenNames[$expectedName] = $file.FullName

        try {
            $data = Import-AtlasDataFile -LiteralPath $file.FullName
            $definition = ConvertTo-AtlasToggleDefinition -Data $data -SourcePath $file.FullName
        }
        catch {
            $results += [pscustomobject]@{ Path = $file.FullName; Problem = $_.Exception.Message }
            continue
        }

        foreach ($problem in @(Get-AtlasToggleDefinitionProblems -Definition $definition -ExpectedName $expectedName)) {
            $results += [pscustomobject]@{ Path = $file.FullName; Problem = $problem }
        }
    }

    # Every companion script must belong to a definition.
    if (-not (Test-Path -LiteralPath $Path -PathType Leaf)) {
        foreach ($script in @(Get-ChildItem -LiteralPath $Path -Recurse -File -Filter '*.ps1')) {
            $definitionPath = [IO.Path]::ChangeExtension($script.FullName, '.psd1')
            if (-not (Test-Path -LiteralPath $definitionPath -PathType Leaf)) {
                $results += [pscustomobject]@{ Path = $script.FullName; Problem = 'is a companion script without a definition.' }
            }
        }
    }

    return $results
}
