<#
.SYNOPSIS
    Generates the committed Atlas catalog from the data-only toggle and tweak definitions.
.DESCRIPTION
    Reads toggle definitions under playbook\Executables\AtlasModules\Toggles and the
    tweak manifest under Scripts\Tweaks to generate these committed references:

      playbook\Executables\AtlasModules\Toggles\catalog.json
          Machine-readable index of every toggle, its states, launchers, elevation and
          state values. Shipped in the payload for AtlasToolbox and other consumers.
      docs\catalog\toggles.md
          Human-readable toggle reference grouped by AtlasDesktop folder.
      docs\catalog\tweaks.md
          Install tweak reference with category and standalone routes, applicability,
          companion work and deliberately disabled definitions.

    Output is deterministic (sorted, LF, UTF-8 without BOM) so CI can diff it. With
    -Validate nothing is written: the outputs are regenerated in memory and compared to
    the files on disk; any difference fails with exit code 1.
.EXAMPLE
    .\Export-AtlasCatalog.ps1            # regenerate the catalog and docs
    .\Export-AtlasCatalog.ps1 -Validate  # CI drift check
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
$catalogPath = Join-Path -Path $togglesRoot -ChildPath 'catalog.json'
$docsRoot = Join-Path -Path $RepoRoot -ChildPath 'docs\catalog'
$togglesDocPath = Join-Path -Path $docsRoot -ChildPath 'toggles.md'
$tweaksDocPath = Join-Path -Path $docsRoot -ChildPath 'tweaks.md'

foreach ($required in @($togglesRoot, $tweaksRoot)) {
    if (-not (Test-Path -LiteralPath $required -PathType Container)) {
        Write-Error "Definition root '$required' does not exist."
        exit 1
    }
}

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

function Get-ToggleCatalog {
    $toggles = New-Object System.Collections.Generic.List[object]
    foreach ($file in @(Get-ChildItem -LiteralPath $togglesRoot -Recurse -File -Filter '*.psd1' | Sort-Object -Property FullName)) {
        $definition = Import-PowerShellDataFile -LiteralPath $file.FullName
        $group = Split-Path -Path (Split-Path -Path $file.FullName -Parent) -Leaf
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
    $gates = New-Object System.Collections.Generic.List[string]
    foreach ($key in 'Option', 'Arch', 'OnUpgrade', 'MinBuild', 'MaxBuild') {
        $value = Get-OptionalValue -Table $tweak -Key $key
        if ($null -ne $value -and [string]$value -ne '') { $gates.Add("$key=$value") }
    }
    if ($tweak.Contains('Oobe') -and $tweak['Oobe'] -eq $false) { $gates.Add('Oobe=false') }
    $work = New-Object System.Collections.Generic.List[string]
    foreach ($key in 'registry', 'services', 'scheduledTasks', 'run', 'removePaths', 'toggle') {
        $count = Get-EntryCount -Table $tweak -Key $key
        if ($count) { $work.Add("$key $count") }
    }
    foreach ($key in 'Script', 'PostUserRegistryRefresh') {
        $value = Get-OptionalValue -Table $tweak -Key $key
        if ($value) { $work.Add("$key ``$value``") }
    }
    return [pscustomobject]@{
        id          = $Id
        name        = [string](Get-OptionalValue -Table $tweak -Key 'Name' -Default $Id)
        description = [string](Get-OptionalValue -Table $tweak -Key 'Description' -Default '')
        gates       = $gates.ToArray()
        work        = $work.ToArray()
    }
}

function Get-TweakCatalog {
    $manifest = Import-PowerShellDataFile -LiteralPath (Join-Path -Path $tweaksRoot -ChildPath 'tweaks.manifest.psd1')
    $categories = New-Object System.Collections.Generic.List[object]
    foreach ($category in @($manifest['Categories'])) {
        $categoryName = [string]$category['Name']
        $tweaks = New-Object System.Collections.Generic.List[object]
        foreach ($tweakName in @($category['Tweaks'])) {
            $tweaks.Add((Get-TweakCatalogEntry -Slug "$categoryName/$tweakName" -Id $tweakName))
        }
        $categories.Add([pscustomobject][ordered]@{
                name        = $categoryName
                parentModes = @($category['ParentModes'])
                tweaks      = $tweaks.ToArray()
            })
    }
    $standalone = foreach ($entry in @($manifest['Standalone'])) {
        $tweak = Get-TweakCatalogEntry -Slug $entry['Slug'] -Id $entry['Slug']
        $tweak.gates = @("ParentModes=$($entry['ParentModes'] -join ', ')") + $tweak.gates
        $tweak
    }
    return [pscustomobject]@{
        categories = $categories.ToArray()
        standalone = @($standalone)
        disabled   = @($manifest['Disabled'])
    }
}

function ConvertTo-MarkdownCell {
    param([AllowNull()][object]$Value)

    if ($null -eq $Value) { return '' }
    return ([string]$Value -replace '\|', '\|' -replace '\r?\n', ' ').Trim()
}

function ConvertTo-ToggleMarkdown {
    param([Parameter(Mandatory = $true)][object[]]$Toggles)

    $lines = New-Object System.Collections.Generic.List[string]
    $lines.Add('# AtlasDesktop toggles')
    $lines.Add('')
    $lines.Add('Generated by `tools/dev/Export-AtlasCatalog.ps1` from the definitions under')
    $lines.Add('`playbook/Executables/AtlasModules/Toggles`. Do not edit by hand; edit the definition and regenerate.')
    $lines.Add('')
    $lines.Add("Toggles: $($Toggles.Count). Elevation is the identity the machine work runs as; a toggle that records no state is a one-shot action.")
    $lines.Add('')
    foreach ($group in @($Toggles | Group-Object -Property group | Sort-Object -Property Name)) {
        $lines.Add("## $($group.Name)")
        $lines.Add('')
        foreach ($toggle in @($group.Group | Sort-Object -Property name)) {
            $flags = @()
            if ($toggle.menu) { $flags += 'menu' }
            if ($toggle.noStateRecord) { $flags += 'no state record' }
            $suffix = if ($flags.Count) { " ($($flags -join ', '))" } else { '' }
            $lines.Add("### $($toggle.name)$suffix")
            $lines.Add('')
            $lines.Add((ConvertTo-MarkdownCell -Value $toggle.description))
            $lines.Add('')
            $lines.Add("Elevation: $($toggle.elevation)")
            if ($toggle.launcher) { $lines.Add("Launcher: ``$($toggle.launcher)``") }
            if ($toggle.warning) {
                $lines.Add('')
                $lines.Add("> $(ConvertTo-MarkdownCell -Value $toggle.warning)")
            }
            $lines.Add('')
            $lines.Add('| State | Value | Launcher | Reboot | Work |')
            $lines.Add('| --- | --- | --- | --- | --- |')
            foreach ($state in @($toggle.states)) {
                $work = @()
                if ($state.work.registry) { $work += "registry $($state.work.registry)" }
                if ($state.work.services) { $work += "services $($state.work.services)" }
                if ($state.work.scheduledTasks) { $work += "tasks $($state.work.scheduledTasks)" }
                foreach ($key in 'machineAction', 'userAction', 'action') {
                    if ($state.work.$key) { $work += "$key ``$($state.work.$key)``" }
                }
                $launcherCell = if ($state.launcher) { "``$($state.launcher)``" } elseif ($state.PSObject.Properties['menuLabel'] -and $state.menuLabel) { "menu: $($state.menuLabel)" } else { '' }
                $lines.Add("| $($state.name) | $(ConvertTo-MarkdownCell -Value $state.stateValue) | $launcherCell | $($state.reboot) | $(ConvertTo-MarkdownCell -Value ($work -join ', ')) |")
            }
            $lines.Add('')
        }
    }
    return ($lines -join "`n")
}

function ConvertTo-TweakMarkdownRow {
    param([Parameter(Mandatory = $true)][psobject]$Tweak)

    return "| ``$($Tweak.id)``<br>$(ConvertTo-MarkdownCell -Value $Tweak.name) | $(ConvertTo-MarkdownCell -Value $Tweak.description) | $(ConvertTo-MarkdownCell -Value ($Tweak.gates -join ', ')) | $(ConvertTo-MarkdownCell -Value ($Tweak.work -join ', ')) |"
}

function ConvertTo-TweakMarkdown {
    param([Parameter(Mandatory = $true)][psobject]$Catalog)

    $lines = New-Object System.Collections.Generic.List[string]
    $lines.Add('# Install tweaks')
    $lines.Add('')
    $lines.Add('Generated by `tools/dev/Export-AtlasCatalog.ps1` from `Scripts/Tweaks/tweaks.manifest.psd1` and')
    $lines.Add('its definitions. Do not edit by hand; edit the source and regenerate.')
    $lines.Add('')
    $categoryCount = @($Catalog.categories | ForEach-Object { $_.tweaks }).Count
    $lines.Add("Categories: $($Catalog.categories.Count). Category tweaks: $categoryCount. Standalone tweaks: $($Catalog.standalone.Count). Disabled definitions: $($Catalog.disabled.Count).")
    $lines.Add('')
    $lines.Add('Category and tweak order follow the manifest. Install modes are the outer `ParentModes` gate;')
    $lines.Add('row gates further restrict applicability. An empty row gate still inherits its install modes.')
    $lines.Add('Standalone steps run at their positions in [the install plan](../architecture.md#one-plan-and-one-orchestrator), outside the category sequence.')
    $lines.Add('')
    foreach ($category in $Catalog.categories) {
        $lines.Add("## $($category.name)")
        $lines.Add('')
        $lines.Add("Install modes: $($category.parentModes -join ', ').")
        $lines.Add('')
        $lines.Add('| Tweak | Description | Gates | Work |')
        $lines.Add('| --- | --- | --- | --- |')
        foreach ($tweak in @($category.tweaks)) {
            $lines.Add((ConvertTo-TweakMarkdownRow -Tweak $tweak))
        }
        $lines.Add('')
    }
    $lines.Add('## Standalone tweaks')
    $lines.Add('')
    $lines.Add('| Tweak | Description | Gates | Work |')
    $lines.Add('| --- | --- | --- | --- |')
    foreach ($tweak in $Catalog.standalone) {
        $lines.Add((ConvertTo-TweakMarkdownRow -Tweak $tweak))
    }
    $lines.Add('')
    $lines.Add('## Disabled definitions')
    $lines.Add('')
    $lines.Add('These definitions ship for reference or future changes but are not dispatched by the install plan.')
    $lines.Add('')
    $lines.Add('| Tweak | Reason |')
    $lines.Add('| --- | --- |')
    foreach ($entry in $Catalog.disabled) {
        $lines.Add("| ``$($entry['Slug'])`` | $(ConvertTo-MarkdownCell -Value $entry['Reason']) |")
    }
    $lines.Add('')
    return ($lines -join "`n")
}

$toggles = Get-ToggleCatalog
$tweaks = Get-TweakCatalog
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
        Write-Host "Catalog validation failed: $problems output(s) differ from the definitions."
        exit 1
    }
    Write-Host "Catalog validation clean: $($toggles.Count) toggle(s), $enabledTweakCount enabled tweak(s), $($tweaks.disabled.Count) disabled definition(s)."
}
else {
    Write-Host "Done: $($toggles.Count) toggle(s), $enabledTweakCount enabled tweak(s), $($tweaks.disabled.Count) disabled definition(s) catalogued."
}
