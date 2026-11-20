<#
.SYNOPSIS
    Generates the committed Atlas catalog from the data-only toggle and tweak definitions.
.DESCRIPTION
    Reads toggle definitions under playbook\Executables\AtlasModules\Toggles, the tweak
    manifest under Scripts\Tweaks and the install plan in Scripts\Install\Install-Plan.ps1
    to generate these committed references:

      playbook\Executables\AtlasModules\Toggles\catalog.json
          Machine-readable index of every toggle, its states, launchers, elevation and
          state values. Included in Atlas's files for AtlasToolbox and other consumers.
      docs\catalog\toggles.md
          Human-readable toggle reference, grouped by definition folder (Toggles\<Group>).
      docs\catalog\tweaks.md
          Install tweak reference with the install modes each category and standalone
          step runs in, each tweak's conditions and work, and the disabled definitions.

    Output is deterministic (sorted, LF, UTF-8 without BOM) so CI can diff it.

    The generator also checks the text it publishes: every Description, Warning and
    disabled Reason must be a sentence that starts with a capital letter and ends with a
    full stop, without the words listed in $script:BannedWords. It also checks that each
    category and standalone step's ParentModes match the route the install plan gives it.
    A normal run reports these as warnings.

    With -Validate nothing is written: the outputs are regenerated in memory and compared
    to the files on disk, and the checks above become failures. Any difference or failed
    check exits with code 1.
.EXAMPLE
    .\Export-AtlasCatalog.ps1            # regenerate the catalog and docs
    .\Export-AtlasCatalog.ps1 -Validate  # CI drift and text check
#>
[CmdletBinding()]
param(
    # Repository root; defaults to two levels above this script (tools\dev).
    [string]$RepoRoot,

    [switch]$Validate
)

Set-StrictMode -Version 3.0
$ErrorActionPreference = 'Stop'

if (-not $RepoRoot) {
    $RepoRoot = (Resolve-Path -LiteralPath (Join-Path -Path $PSScriptRoot -ChildPath '..\..')).Path
}

$modulesRoot = Join-Path -Path $RepoRoot -ChildPath 'playbook\Executables\AtlasModules'
$togglesRoot = Join-Path -Path $modulesRoot -ChildPath 'Toggles'
$tweaksRoot = Join-Path -Path $modulesRoot -ChildPath 'Scripts\Tweaks'
$installPlanPath = Join-Path -Path $modulesRoot -ChildPath 'Scripts\Install\Install-Plan.ps1'
$catalogPath = Join-Path -Path $togglesRoot -ChildPath 'catalog.json'
$docsRoot = Join-Path -Path $RepoRoot -ChildPath 'docs\catalog'
$togglesDocPath = Join-Path -Path $docsRoot -ChildPath 'toggles.md'
$tweaksDocPath = Join-Path -Path $docsRoot -ChildPath 'tweaks.md'

# Relative links from docs\catalog to the schema READMEs.
$togglesReadmeLink = '../../playbook/Executables/AtlasModules/Toggles/README.md'
$tweaksReadmeLink = '../../playbook/Executables/AtlasModules/Scripts/Tweaks/README.md'

# The install modes in the order the plan defines them.
$script:InstallModes = @('Fresh', 'Upgrade', 'Reapply', 'Rebase')

# Filler and house-style words a published description must not use (docs/style.md).
$script:BannedWords = @('QoL', 'anyways', 'simply', 'really', 'basically', 'payload', 'ships')

foreach ($required in @($togglesRoot, $tweaksRoot)) {
    if (-not (Test-Path -LiteralPath $required -PathType Container)) {
        Write-Error "Definition root '$required' does not exist."
        exit 1
    }
}
if (-not (Test-Path -LiteralPath $installPlanPath -PathType Leaf)) {
    Write-Error "Install plan '$installPlanPath' does not exist."
    exit 1
}

$script:TextProblems = New-Object System.Collections.Generic.List[string]

function Get-OptionalValue {
    param(
        [Parameter(Mandatory = $true)][System.Collections.IDictionary]$Table,
        [Parameter(Mandatory = $true)][string]$Key,
        $Default = $null
    )

    if ($Table.Contains($Key) -and $null -ne $Table[$Key]) {
        return $Table[$Key]
    }
    return $Default
}

function Get-EntryCount {
    param([Parameter(Mandatory = $true)][System.Collections.IDictionary]$Table, [Parameter(Mandatory = $true)][string]$Key)

    $value = Get-OptionalValue -Table $Table -Key $Key
    if ($null -eq $value) { return 0 }
    return @($value).Count
}

function Add-TextProblem {
    param([Parameter(Mandatory = $true)][string]$Problem)

    $script:TextProblems.Add($Problem)
}

# A published text must read as a sentence: a capital letter (or an opening quote,
# backtick or bracket) first, a full stop last, and none of the banned words.
function Test-PublishedText {
    param(
        [Parameter(Mandatory = $true)][string]$Label,
        [AllowNull()][object]$Text
    )

    if ($null -eq $Text -or [string]::IsNullOrWhiteSpace([string]$Text)) { return }
    $value = ([string]$Text).Trim()
    if ($value -cnotmatch '\A[A-Z0-9`''"(]') {
        Add-TextProblem -Problem "${Label}: start with a capital letter."
    }
    if ($value -cnotmatch '[^.]\.\z') {
        Add-TextProblem -Problem "${Label}: end with a single full stop."
    }
    foreach ($word in $script:BannedWords) {
        if ($value -match "(?i)\b$([regex]::Escape($word))\b") {
            Add-TextProblem -Problem "${Label}: avoid '$word'; state the concrete effect."
        }
    }
}

function Join-WordList {
    param([Parameter(Mandatory = $true)][AllowEmptyCollection()][string[]]$Words)

    if ($Words.Count -le 1) { return ($Words -join '') }
    return (($Words[0..($Words.Count - 2)] -join ', ') + ' and ' + $Words[-1])
}

# Splits prose into sentences so the Markdown keeps one sentence per line.
function ConvertTo-SentenceLine {
    param([AllowNull()][object]$Text)

    if ($null -eq $Text) { return @() }
    $clean = (([string]$Text) -replace '\s+', ' ').Trim()
    if (-not $clean) { return @() }
    return @([regex]::Split($clean, '(?<=[.!?])\s+(?=[A-Z0-9`''"(])') | Where-Object { $_ })
}

function ConvertTo-MarkdownCell {
    param([AllowNull()][object]$Value)

    if ($null -eq $Value) { return '' }
    return ([string]$Value -replace '\|', '\|' -replace '\r?\n', ' ').Trim()
}

# The install plan decides which modes run each step; read it rather than restate it.
# Returns step key -> the modes whose plan contains that step, in plan order.
function Get-InstallPlanRoute {
    . $installPlanPath
    $route = @{}
    foreach ($mode in $script:InstallModes) {
        foreach ($step in @(Get-AtlasInstallPlan -Mode $mode)) {
            $key = [string]$step.Key
            if (-not $route.ContainsKey($key)) {
                $route[$key] = New-Object System.Collections.Generic.List[string]
            }
            $route[$key].Add($mode)
        }
    }
    return $route
}

# Whether a state changes the signed-in user's own settings, as the toggle engine
# decides it (Get-AtlasToggleStateWork): plain HKCU values or a UserAction, in a
# toggle that needs elevation. The engine runs that part only in the user's own,
# unelevated process, so an elevated caller must start the launcher as that user.
# HKCU policy keys are written by the machine part.
function Test-UserWork {
    param(
        [Parameter(Mandatory = $true)][System.Collections.IDictionary]$Definition,
        [Parameter(Mandatory = $true)][System.Collections.IDictionary]$State
    )

    if ([string](Get-OptionalValue -Table $Definition -Key 'Elevation' -Default 'None') -ceq 'None') { return $false }
    if ($null -ne (Get-OptionalValue -Table $State -Key 'UserAction')) { return $true }
    foreach ($entry in @(Get-OptionalValue -Table $State -Key 'Registry' -Default @())) {
        if ([string]$entry['Path'] -notmatch '^(?i)(?:Registry::)?(?:HKCU:?|HKEY_CURRENT_USER)\\(.*)$') { continue }
        $subPath = $Matches[1].Trim('\')
        if ($subPath -notmatch '(?i)^Software\\(?:Microsoft\\Windows\\CurrentVersion\\)?Policies(?:\\|$)') { return $true }
    }
    return $false
}

function Get-ToggleCatalog {
    $toggles = New-Object System.Collections.Generic.List[object]
    foreach ($file in @(Get-ChildItem -LiteralPath $togglesRoot -Recurse -File -Filter '*.psd1' | Sort-Object -Property FullName)) {
        $definition = Import-PowerShellDataFile -LiteralPath $file.FullName
        $group = Split-Path -Path (Split-Path -Path $file.FullName -Parent) -Leaf
        $label = "Toggles\$group\$($file.Name)"
        Test-PublishedText -Label "$label Description" -Text (Get-OptionalValue -Table $definition -Key 'Description')
        Test-PublishedText -Label "$label Warning" -Text (Get-OptionalValue -Table $definition -Key 'Warning')
        $states = New-Object System.Collections.Generic.List[object]
        foreach ($state in @(Get-OptionalValue -Table $definition -Key 'States' -Default @())) {
            # Broker-only choices are implementation details, not user-facing toggles.
            if ([bool](Get-OptionalValue -Table $state -Key 'Internal' -Default $false)) { continue }
            $record = [ordered]@{
                name       = [string]$state['Name']
                stateValue = Get-OptionalValue -Table $state -Key 'StateValue'
                launcher   = Get-OptionalValue -Table $state -Key 'Launcher'
                reboot     = [string](Get-OptionalValue -Table $state -Key 'Reboot' -Default 'None')
            }
            $toolboxLauncher = Get-OptionalValue -Table $state -Key 'ToolboxLauncher'
            if ($null -ne $toolboxLauncher) { $record['toolboxLauncher'] = [string]$toolboxLauncher }
            $menuLabel = Get-OptionalValue -Table $state -Key 'MenuLabel'
            if ($null -ne $menuLabel) { $record['menuLabel'] = [string]$menuLabel }
            if ([bool](Get-OptionalValue -Table $state -Key 'NoStateRecord' -Default $false)) { $record['noStateRecord'] = $true }
            $record['work'] = [ordered]@{
                registry       = Get-EntryCount -Table $state -Key 'Registry'
                services       = Get-EntryCount -Table $state -Key 'Services'
                scheduledTasks = Get-EntryCount -Table $state -Key 'ScheduledTasks'
                machineAction  = Get-OptionalValue -Table $state -Key 'MachineAction'
                userAction     = Get-OptionalValue -Table $state -Key 'UserAction'
                action         = Get-OptionalValue -Table $state -Key 'Action'
                user           = Test-UserWork -Definition $definition -State $state
            }
            $states.Add([pscustomobject]$record)
        }

        $toggle = [ordered]@{
            name          = [string]$definition['Name']
            group         = $group
            description   = [string](Get-OptionalValue -Table $definition -Key 'Description' -Default '')
            elevation     = [string](Get-OptionalValue -Table $definition -Key 'Elevation' -Default 'None')
            noStateRecord = [bool](Get-OptionalValue -Table $definition -Key 'NoStateRecord' -Default $false)
            menu          = [bool](Get-OptionalValue -Table $definition -Key 'Menu' -Default $false)
            launcher      = Get-OptionalValue -Table $definition -Key 'Launcher'
            warning       = Get-OptionalValue -Table $definition -Key 'Warning'
            states        = $states.ToArray()
        }
        $toggles.Add([pscustomobject]$toggle)
    }
    return @($toggles | Sort-Object -Property group, name)
}

function Get-TweakCatalogEntry {
    param(
        [Parameter(Mandatory = $true)][string]$Slug,
        [Parameter(Mandatory = $true)][string]$Id
    )

    $path = Join-Path -Path $tweaksRoot -ChildPath (($Slug -replace '/', '\') + '.psd1')
    if (-not (Test-Path -LiteralPath $path -PathType Leaf)) {
        throw "Manifest entry '$Slug' has no definition at '$path'."
    }
    $tweak = Import-PowerShellDataFile -LiteralPath $path
    Test-PublishedText -Label "Tweaks\$($Slug -replace '/', '\').psd1 Description" -Text (Get-OptionalValue -Table $tweak -Key 'Description')

    # Work follows the machine pass order in the tweak README.
    $work = New-Object System.Collections.Generic.List[string]
    foreach ($key in 'Registry', 'Services', 'ScheduledTasks') {
        $count = Get-EntryCount -Table $tweak -Key $key
        if ($count) { $work.Add("$key $count") }
    }
    foreach ($entry in @(Get-OptionalValue -Table $tweak -Key 'Toggle' -Default @())) {
        $toggleName = [string]$entry['Name']
        $work.Add("Toggle [$toggleName](toggles.md#$($toggleName.ToLowerInvariant())) $($entry['State'])")
    }
    foreach ($key in 'Run', 'RemovePaths') {
        $count = Get-EntryCount -Table $tweak -Key $key
        if ($count) { $work.Add("$key $count") }
    }
    $companion = Get-OptionalValue -Table $tweak -Key 'Script'
    if ($companion) {
        $asUser = if ([string](Get-OptionalValue -Table $tweak -Key 'RunAs') -ceq 'User') { ' as the install user' } else { '' }
        $work.Add("Script ``$companion``$asUser")
    }
    $refresh = Get-OptionalValue -Table $tweak -Key 'PostUserRegistryRefresh'
    if ($refresh) { $work.Add("PostUserRegistryRefresh ``$refresh``") }

    return [pscustomobject]@{
        id          = $Id
        slug        = $Slug
        name        = [string](Get-OptionalValue -Table $tweak -Key 'Name' -Default $Id)
        description = [string](Get-OptionalValue -Table $tweak -Key 'Description' -Default '')
        option      = [string](Get-OptionalValue -Table $tweak -Key 'Option' -Default '')
        arch        = [string](Get-OptionalValue -Table $tweak -Key 'Arch' -Default '')
        onUpgrade   = [string](Get-OptionalValue -Table $tweak -Key 'OnUpgrade' -Default 'Both')
        onRebase    = [string](Get-OptionalValue -Table $tweak -Key 'OnRebase' -Default '')
        minBuild    = Get-OptionalValue -Table $tweak -Key 'MinBuild'
        maxBuild    = Get-OptionalValue -Table $tweak -Key 'MaxBuild'
        work        = $work.ToArray()
    }
}

# Compares a manifest ParentModes list with the install plan's route for the step.
# ParentModes names the Fresh and Upgrade routes; Reapply and Rebase follow the plan.
function Test-ParentModeRoute {
    param(
        [Parameter(Mandatory = $true)][string]$Label,
        [Parameter(Mandatory = $true)][AllowEmptyCollection()][string[]]$ParentModes,
        [Parameter(Mandatory = $true)][AllowEmptyCollection()][string[]]$RouteModes
    )

    if ($RouteModes.Count -eq 0) {
        Add-TextProblem -Problem "${Label}: the install plan has no step for it."
        return
    }
    $expected = @('Fresh', 'Upgrade' | Where-Object { $RouteModes -ccontains $_ })
    $declared = @($ParentModes | Sort-Object)
    if (($declared -join ',') -cne (@($expected | Sort-Object) -join ',')) {
        Add-TextProblem -Problem "${Label}: ParentModes [$($ParentModes -join ', ')] don't match the install plan, which runs it in $(Join-WordList -Words $RouteModes)."
    }
}

function Get-TweakCatalog {
    param([Parameter(Mandatory = $true)][hashtable]$Route)

    $manifest = Import-PowerShellDataFile -LiteralPath (Join-Path -Path $tweaksRoot -ChildPath 'tweaks.manifest.psd1')
    $categories = New-Object System.Collections.Generic.List[object]
    foreach ($category in @($manifest['Categories'])) {
        $categoryName = [string]$category['Name']
        $routeModes = @()
        if ($Route.ContainsKey("Tweaks/$categoryName")) { $routeModes = @($Route["Tweaks/$categoryName"]) }
        Test-ParentModeRoute -Label "Category '$categoryName'" -ParentModes @($category['ParentModes']) -RouteModes $routeModes
        $tweaks = New-Object System.Collections.Generic.List[object]
        foreach ($tweakName in @($category['Tweaks'])) {
            $tweaks.Add((Get-TweakCatalogEntry -Slug "$categoryName/$tweakName" -Id $tweakName))
        }
        $categories.Add([pscustomobject][ordered]@{
                name       = $categoryName
                routeModes = $routeModes
                tweaks     = $tweaks.ToArray()
            })
    }
    $standalone = foreach ($entry in @($manifest['Standalone'])) {
        $slug = [string]$entry['Slug']
        $routeModes = @()
        if ($Route.ContainsKey("Tweak/$slug")) { $routeModes = @($Route["Tweak/$slug"]) }
        Test-ParentModeRoute -Label "Standalone '$slug'" -ParentModes @($entry['ParentModes']) -RouteModes $routeModes
        $tweak = Get-TweakCatalogEntry -Slug $slug -Id $slug
        $tweak | Add-Member -NotePropertyName routeModes -NotePropertyValue $routeModes
        $tweak
    }
    foreach ($entry in @($manifest['Disabled'])) {
        Test-PublishedText -Label "Disabled '$($entry['Slug'])' Reason" -Text $entry['Reason']
        $path = Join-Path -Path $tweaksRoot -ChildPath ((([string]$entry['Slug']) -replace '/', '\') + '.psd1')
        if (Test-Path -LiteralPath $path -PathType Leaf) {
            $definition = Import-PowerShellDataFile -LiteralPath $path
            Test-PublishedText -Label "Tweaks\$(([string]$entry['Slug']) -replace '/', '\').psd1 Description" -Text (Get-OptionalValue -Table $definition -Key 'Description')
        }
    }
    return [pscustomobject]@{
        categories = $categories.ToArray()
        standalone = @($standalone)
        disabled   = @($manifest['Disabled'])
    }
}

# Plain-words conditions for one tweak within the install modes its route runs in.
function Get-TweakCondition {
    param(
        [Parameter(Mandatory = $true)][psobject]$Tweak,
        [Parameter(Mandatory = $true)][AllowEmptyCollection()][string[]]$RouteModes
    )

    $conditions = New-Object System.Collections.Generic.List[string]
    if ($Tweak.option) { $conditions.Add("Only with option ``$($Tweak.option)``") }
    switch -CaseSensitive ($Tweak.arch) {
        'ARM64' { $conditions.Add('ARM64 only') }
        'X64' { $conditions.Add('x64 only') }
    }

    $allowed = switch -CaseSensitive ($Tweak.onUpgrade) {
        'Skip' {
            if ($Tweak.onRebase -ceq 'Run') { @('Fresh', 'Rebase') } else { @('Fresh') }
        }
        'Only' { @('Upgrade', 'Reapply', 'Rebase') }
        default { $script:InstallModes }
    }
    $effective = @($RouteModes | Where-Object { $allowed -ccontains $_ })
    if ($effective.Count -gt 0 -and $effective.Count -lt $RouteModes.Count) {
        $withoutFresh = @($RouteModes | Where-Object { $_ -cne 'Fresh' })
        if ($RouteModes -ccontains 'Fresh' -and ($effective -join ',') -ceq ($withoutFresh -join ',')) {
            $conditions.Add('Not on fresh installs')
        }
        else {
            $conditions.Add("$(Join-WordList -Words $effective) installs only")
        }
    }

    if ($null -ne $Tweak.minBuild) { $conditions.Add("Windows build $($Tweak.minBuild) or later") }
    if ($null -ne $Tweak.maxBuild) { $conditions.Add("Windows build $($Tweak.maxBuild) or earlier") }
    return $conditions.ToArray()
}

function ConvertTo-ToggleMarkdown {
    param([Parameter(Mandatory = $true)][object[]]$Toggles)

    $lines = New-Object System.Collections.Generic.List[string]
    $lines.Add('# AtlasDesktop toggles')
    $lines.Add('')
    $lines.Add('This page lists every toggle: a setting you can change after the install from the AtlasDesktop folder or Atlas Toolbox.')
    $lines.Add('It''s for contributors and support, and is generated by `tools/dev/Export-AtlasCatalog.ps1` from the definitions under `playbook/Executables/AtlasModules/Toggles`.')
    $lines.Add('Don''t edit it by hand: edit the definition and regenerate.')
    $lines.Add("The [toggle definition schema]($togglesReadmeLink#definition-schema) describes every key.")
    $lines.Add('')
    $lines.Add("Toggles: $($Toggles.Count).")
    $lines.Add('')
    $lines.Add('## How to read this page')
    $lines.Add('')
    $lines.Add('Toggles are grouped by their definition folder, `Toggles/<Group>`.')
    $lines.Add('')
    $lines.Add('- **Elevation** is the identity the machine work runs as.')
    $lines.Add('  `None` runs in the launcher''s own process, `Admin` runs as Administrator after a UAC prompt, and `TrustedInstaller` runs in the silent TrustedInstaller broker.')
    $lines.Add('- **Menu launcher** is the one launcher of a menu toggle, which asks which state to apply.')
    $lines.Add('- **Records no state** marks a one-shot action: Atlas doesn''t record it, and updates don''t replay it.')
    $lines.Add('- **Value** is the number Atlas records under `HKLM\SOFTWARE\AtlasOS\Services\<Name>` when the state is applied.')
    $lines.Add('- **Restart** is the state''s `Reboot` key.')
    $lines.Add('  `Recommend` suggests a restart, `Prompt` says a restart is needed and offers one, `RestartExplorer` restarts File Explorer, and `SignOut` offers to sign out.')
    $lines.Add('- **Work** lists what the state declares.')
    $lines.Add('  A number counts entries, so `Registry 2` is two registry entries.')
    $lines.Add('  `MachineAction` runs with the toggle''s elevation, `UserAction` runs as the signed-in user without elevation, and `Action` runs in the launcher''s own process.')
    $lines.Add('')
    foreach ($group in @($Toggles | Group-Object -Property group | Sort-Object -Property Name)) {
        $lines.Add("## $($group.Name)")
        $lines.Add('')
        foreach ($toggle in @($group.Group | Sort-Object -Property name)) {
            $lines.Add("### $($toggle.name)")
            $lines.Add('')
            $descriptionLines = @(ConvertTo-SentenceLine -Text $toggle.description)
            if ($descriptionLines.Count) {
                foreach ($sentence in $descriptionLines) { $lines.Add($sentence) }
                $lines.Add('')
            }
            $lines.Add("- Elevation: $($toggle.elevation)")
            if ($toggle.launcher) { $lines.Add("- Menu launcher: ``$($toggle.launcher)``") }
            if ($toggle.noStateRecord) { $lines.Add('- Records no state') }
            $warningLines = @(ConvertTo-SentenceLine -Text $toggle.warning)
            if ($warningLines.Count) {
                $lines.Add('')
                $lines.Add('> [!WARNING]')
                foreach ($sentence in $warningLines) { $lines.Add("> $sentence") }
            }
            $lines.Add('')
            $lines.Add('| State | Value | Launcher | Restart | Work |')
            $lines.Add('| --- | --- | --- | --- | --- |')
            foreach ($state in @($toggle.states)) {
                $work = @()
                if ($state.work.registry) { $work += "Registry $($state.work.registry)" }
                if ($state.work.services) { $work += "Services $($state.work.services)" }
                if ($state.work.scheduledTasks) { $work += "ScheduledTasks $($state.work.scheduledTasks)" }
                foreach ($key in 'MachineAction', 'UserAction', 'Action') {
                    if ($state.work.$key) { $work += "$key ``$($state.work.$key)``" }
                }
                $launcherCell = if ($state.launcher) { "``$($state.launcher)``" } elseif ($state.PSObject.Properties['menuLabel'] -and $state.menuLabel) { "Menu: $($state.menuLabel)" } else { '' }
                $lines.Add("| $($state.name) | $(ConvertTo-MarkdownCell -Value $state.stateValue) | $launcherCell | $($state.reboot) | $(ConvertTo-MarkdownCell -Value ($work -join ', ')) |")
            }
            $lines.Add('')
        }
    }
    return ($lines -join "`n")
}

function ConvertTo-TweakMarkdownRow {
    param(
        [Parameter(Mandatory = $true)][psobject]$Tweak,
        [Parameter(Mandatory = $true)][AllowEmptyCollection()][string[]]$RouteModes,
        [switch]$WithModes
    )

    $conditions = @(Get-TweakCondition -Tweak $Tweak -RouteModes $RouteModes)
    $cells = @(
        "``$($Tweak.id)``<br>$(ConvertTo-MarkdownCell -Value $Tweak.name)"
        (ConvertTo-MarkdownCell -Value $Tweak.description)
    )
    if ($WithModes) { $cells += (Join-WordList -Words $RouteModes) }
    $cells += (ConvertTo-MarkdownCell -Value ($conditions -join '; '))
    $cells += (ConvertTo-MarkdownCell -Value ($Tweak.work -join ', '))
    return "| $($cells -join ' | ') |"
}

function ConvertTo-TweakMarkdown {
    param([Parameter(Mandatory = $true)][psobject]$Catalog)

    $lines = New-Object System.Collections.Generic.List[string]
    $lines.Add('# Install tweaks')
    $lines.Add('')
    $lines.Add('This page lists the tweaks the Atlas install applies, in the order it runs them.')
    $lines.Add('It''s for contributors and support, and is generated by `tools/dev/Export-AtlasCatalog.ps1` from `Scripts/Tweaks/tweaks.manifest.psd1`, the definitions it names and the install plan.')
    $lines.Add('Don''t edit it by hand: edit the source and regenerate.')
    $lines.Add("The [tweak definition schema]($tweaksReadmeLink#tweak-schema) describes every key.")
    $lines.Add('')
    $categoryCount = @($Catalog.categories | ForEach-Object { $_.tweaks }).Count
    $lines.Add("- Categories: $($Catalog.categories.Count)")
    $lines.Add("- Category tweaks: $categoryCount")
    $lines.Add("- Standalone tweaks: $($Catalog.standalone.Count)")
    $lines.Add("- Disabled definitions: $($Catalog.disabled.Count)")
    $lines.Add('')
    $lines.Add('## How to read this page')
    $lines.Add('')
    $lines.Add('Categories and the tweaks in them follow the manifest order.')
    $lines.Add('Standalone tweaks run at their own positions in [the install plan](../architecture.md#one-plan-and-one-orchestrator), outside the category sequence.')
    $lines.Add('')
    $lines.Add('- **Install modes** are the modes in which the install plan runs a category or standalone tweak.')
    $lines.Add('  Fresh is a new install, Upgrade an update to a newer Atlas, Reapply a reinstall of the same version, and Rebase puts Atlas back on a Windows that rebuilt itself during a move to a newer release.')
    $lines.Add('- **Conditions** narrow when a tweak runs within those modes; an empty cell means it runs whenever its category runs.')
    $lines.Add('  "Only with option `x`" needs that choice in Atlas Manager.')
    $lines.Add('  "Fresh installs only" comes from `OnUpgrade = ''Skip''`, and "Fresh and Rebase installs only" adds `OnRebase = ''Run''`.')
    $lines.Add('  "Not on fresh installs" comes from `OnUpgrade = ''Only''`.')
    $lines.Add('  "ARM64 only" and "x64 only" come from `Arch`, and the Windows build conditions from `MinBuild` and `MaxBuild`.')
    $lines.Add('- **Work** lists the keys the definition declares, in the order the install applies them.')
    $lines.Add('  A number counts entries, so `Registry 3` is three registry entries, and `Toggle` names the toggle state the tweak applies and records.')
    $lines.Add('')
    foreach ($category in $Catalog.categories) {
        $lines.Add("## $($category.name)")
        $lines.Add('')
        $lines.Add("Install modes: $(Join-WordList -Words @($category.routeModes)).")
        $lines.Add('')
        $lines.Add('| Tweak | Description | Conditions | Work |')
        $lines.Add('| --- | --- | --- | --- |')
        foreach ($tweak in @($category.tweaks)) {
            $lines.Add((ConvertTo-TweakMarkdownRow -Tweak $tweak -RouteModes @($category.routeModes)))
        }
        $lines.Add('')
    }
    $lines.Add('## Standalone tweaks')
    $lines.Add('')
    $lines.Add('| Tweak | Description | Install modes | Conditions | Work |')
    $lines.Add('| --- | --- | --- | --- | --- |')
    foreach ($tweak in $Catalog.standalone) {
        $lines.Add((ConvertTo-TweakMarkdownRow -Tweak $tweak -RouteModes @($tweak.routeModes) -WithModes))
    }
    $lines.Add('')
    $lines.Add('## Disabled definitions')
    $lines.Add('')
    $lines.Add('The install plan doesn''t run these definitions.')
    $lines.Add('Each stays in the folder for reference, with the reason it''s disabled.')
    $lines.Add('')
    $lines.Add('| Tweak | Reason |')
    $lines.Add('| --- | --- |')
    foreach ($entry in $Catalog.disabled) {
        $lines.Add("| ``$($entry['Slug'])`` | $(ConvertTo-MarkdownCell -Value $entry['Reason']) |")
    }
    $lines.Add('')
    return ($lines -join "`n")
}

$route = Get-InstallPlanRoute
$toggles = Get-ToggleCatalog
$tweaks = Get-TweakCatalog -Route $route
$enabledTweakCount = @($tweaks.categories | ForEach-Object { $_.tweaks }).Count + $tweaks.standalone.Count

$catalog = [ordered]@{
    schemaVersion = 1
    toggles       = $toggles
}
$outputs = [ordered]@{
    $catalogPath    = ((ConvertTo-Json -InputObject $catalog -Depth 8) -replace "`r`n", "`n") + "`n"
    $togglesDocPath = (ConvertTo-ToggleMarkdown -Toggles $toggles).TrimEnd() + "`n"
    $tweaksDocPath  = (ConvertTo-TweakMarkdown -Catalog $tweaks).TrimEnd() + "`n"
}

$encoding = New-Object System.Text.UTF8Encoding($false)
$problems = 0
foreach ($problem in $script:TextProblems) {
    if ($Validate) {
        Write-Host "Text: $problem"
        $problems++
    }
    else {
        Write-Warning $problem
    }
}
foreach ($path in $outputs.Keys) {
    $expected = $outputs[$path]
    $relative = $path.Substring($RepoRoot.Length).TrimStart('\', '/')
    if ($Validate) {
        if (-not (Test-Path -LiteralPath $path -PathType Leaf)) {
            Write-Host "Missing: $relative"
            $problems++
            continue
        }
        $actual = [IO.File]::ReadAllText($path, $encoding)
        if ($actual -cne $expected) {
            Write-Host "Drifted: $relative (regenerate with tools\dev\Export-AtlasCatalog.ps1)"
            $problems++
        }
        continue
    }
    $directory = Split-Path -Path $path -Parent
    if (-not (Test-Path -LiteralPath $directory -PathType Container)) {
        New-Item -Path $directory -ItemType Directory -Force | Out-Null
    }
    if ((Test-Path -LiteralPath $path -PathType Leaf) -and ([IO.File]::ReadAllText($path, $encoding) -ceq $expected)) {
        continue
    }
    [IO.File]::WriteAllText($path, $expected, $encoding)
    Write-Host "Wrote: $relative"
}

if ($Validate) {
    if ($problems) {
        Write-Host "Catalog validation failed: $problems problem(s)."
        exit 1
    }
    Write-Host "Catalog validation clean: $($toggles.Count) toggle(s), $enabledTweakCount enabled tweak(s), $($tweaks.disabled.Count) disabled definition(s)."
}
else {
    Write-Host "Done: $($toggles.Count) toggle(s), $enabledTweakCount enabled tweak(s), $($tweaks.disabled.Count) disabled definition(s) catalogued."
}
