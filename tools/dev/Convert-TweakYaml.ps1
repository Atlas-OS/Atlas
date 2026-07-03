<#
.SYNOPSIS
    Dev aid: converts an AME leaf tweak YAML file into an Atlas declarative tweak .psd1.
.DESCRIPTION
    Parses the AME playbook YAML subset used by Atlas leaf tweaks (custom !tags,
    line-based - no YAML library) and emits the equivalent data-only tweak .psd1 plus a
    fidelity report (actions in / entries out / unmapped constructs). Explanatory YAML
    comments are preserved next to the emitted entries.

    Constructs the schema cannot express (e.g. !powerShell actions, per-action option
    gating that differs within one file, block scalars) are listed as unmapped and must
    be hand-converted. This is a development aid, not a runtime component.
.PARAMETER Path
    The leaf tweak YAML file to convert.
.PARAMETER Destination
    Optional output .psd1 path. When omitted, the .psd1 text is written to the pipeline.
.PARAMETER PassThru
    Also emit the fidelity report object.
.EXAMPLE
    .\Convert-TweakYaml.ps1 -Path tweaks\privacy\disable-pca.yml -Destination out\disable-pca.psd1 -PassThru
#>
[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)]
    [ValidateNotNullOrEmpty()]
    [string]$Path,

    [string]$Destination,

    [switch]$PassThru
)

$ErrorActionPreference = 'Stop'

function ConvertFrom-YamlScalar {
    <#
    .SYNOPSIS
        Unquotes a YAML scalar ('single quoted' or bare) into a plain string.
    #>
    param([string]$Value)

    $trimmed = ([string]$Value).Trim()
    if ($trimmed.Length -ge 2 -and $trimmed.StartsWith("'") -and $trimmed.EndsWith("'")) {
        return $trimmed.Substring(1, $trimmed.Length - 2).Replace("''", "'")
    }
    if ($trimmed.Length -ge 2 -and $trimmed.StartsWith('"') -and $trimmed.EndsWith('"')) {
        return $trimmed.Substring(1, $trimmed.Length - 2)
    }

    return $trimmed
}

function Remove-YamlInlineComment {
    <#
    .SYNOPSIS
        Splits a YAML value into the value itself and a trailing inline comment,
        honoring single-quoted strings.
    #>
    param([string]$Value)

    $inSingle = $false
    for ($i = 0; $i -lt $Value.Length; $i++) {
        $char = $Value[$i]
        if ($char -eq "'") {
            $inSingle = -not $inSingle
        }
        elseif ($char -eq '#' -and -not $inSingle) {
            return [pscustomobject]@{
                Value   = $Value.Substring(0, $i).TrimEnd()
                Comment = $Value.Substring($i).Trim()
            }
        }
    }

    return [pscustomobject]@{ Value = $Value.Trim(); Comment = $null }
}

function ConvertFrom-YamlFlowMap {
    <#
    .SYNOPSIS
        Parses a single-line YAML flow mapping ('{key: value, key: value}') into an
        ordered hashtable of raw string values.
    #>
    param([string]$Text)

    $map = [ordered]@{}
    $inner = $Text.Trim()
    if ($inner.StartsWith('{')) { $inner = $inner.Substring(1) }
    if ($inner.EndsWith('}')) { $inner = $inner.Substring(0, $inner.Length - 1) }

    # Split on top-level commas (single quotes are the only quoting used in the tweaks).
    $parts = New-Object System.Collections.Generic.List[string]
    $current = New-Object System.Text.StringBuilder
    $inSingle = $false
    foreach ($char in $inner.ToCharArray()) {
        if ($char -eq "'") { $inSingle = -not $inSingle }
        if ($char -eq ',' -and -not $inSingle) {
            $parts.Add($current.ToString())
            $null = $current.Clear()
        }
        else {
            $null = $current.Append($char)
        }
    }
    $parts.Add($current.ToString())

    foreach ($part in $parts) {
        if ([string]::IsNullOrWhiteSpace($part)) { continue }
        $separator = $part.IndexOf(':')
        if ($separator -lt 0) { continue }
        $key = $part.Substring(0, $separator).Trim()
        $map[$key] = ConvertFrom-YamlScalar -Value $part.Substring($separator + 1)
    }

    return $map
}

function Read-AmeTweakYaml {
    <#
    .SYNOPSIS
        Line-based parser for the AME leaf tweak YAML subset. Returns the header fields,
        the action list (tag + properties + attached comments) and unparsed constructs.
    #>
    param([string]$FilePath)

    $lines = [System.IO.File]::ReadAllLines($FilePath)

    $result = [pscustomobject]@{
        Title            = $null
        Description      = $null
        HeaderGates      = [ordered]@{}
        Actions          = New-Object System.Collections.Generic.List[object]
        TrailingComments = @()
        Unparsed         = New-Object System.Collections.Generic.List[string]
    }

    $inActions = $false
    $pendingComments = New-Object System.Collections.Generic.List[string]
    $index = 0

    while ($index -lt $lines.Count) {
        $line = $lines[$index]
        $trimmed = $line.Trim()
        $index++

        if (-not $inActions) {
            if ($trimmed -eq 'actions:') { $inActions = $true; continue }
            if ($trimmed -match '^title:\s*(.+)$') { $result.Title = ConvertFrom-YamlScalar -Value $Matches[1]; continue }
            if ($trimmed -match '^description:\s*(.+)$') { $result.Description = ConvertFrom-YamlScalar -Value $Matches[1]; continue }
            if ($trimmed -match '^(onUpgrade|oobe|option|builds):\s*(.+)$') { $result.HeaderGates[$Matches[1]] = $Matches[2].Trim(); continue }
            if ($trimmed -eq '---' -or $trimmed -eq '' -or $trimmed.StartsWith('#')) { continue }
            $result.Unparsed.Add("Header line not understood: '$trimmed'")
            continue
        }

        if ($trimmed -eq '') { continue }

        if ($trimmed.StartsWith('#')) {
            $pendingComments.Add($trimmed)
            continue
        }

        if ($trimmed -match '^-\s*!(\w+):\s*(.*)$') {
            $tag = $Matches[1]
            $rest = $Matches[2].Trim()
            $action = [pscustomobject]@{
                Tag      = $tag
                Props    = [ordered]@{}
                Comments = @($pendingComments)
            }
            $pendingComments.Clear()

            if ($rest.StartsWith('{')) {
                $action.Props = ConvertFrom-YamlFlowMap -Text $rest
            }
            else {
                # Block mapping: consume 'key: value' lines until the next action,
                # comment or dedent. Block scalars (key: |) are not supported.
                while ($index -lt $lines.Count) {
                    $next = $lines[$index]
                    $nextTrimmed = $next.Trim()
                    if ($nextTrimmed -eq '') { $index++; continue }
                    if ($nextTrimmed.StartsWith('#') -or $nextTrimmed.StartsWith('-')) { break }
                    if ($nextTrimmed -match '^(\w+):\s*(.*)$') {
                        $key = $Matches[1]
                        $rawValue = $Matches[2]
                        $index++
                        if ($rawValue.Trim() -in @('|', '>', '|-', '>-')) {
                            $result.Unparsed.Add("Action '!$tag' uses a block scalar for '$key' (hand-convert).")
                            while ($index -lt $lines.Count -and ($lines[$index].Trim() -eq '' -or $lines[$index] -match '^\s{6,}')) { $index++ }
                            continue
                        }
                        $split = Remove-YamlInlineComment -Value $rawValue
                        if ($split.Comment) { $action.Comments += $split.Comment }
                        $action.Props[$key] = ConvertFrom-YamlScalar -Value $split.Value
                    }
                    else {
                        break
                    }
                }
            }

            $result.Actions.Add($action)
            continue
        }

        $result.Unparsed.Add("Line not understood: '$trimmed'")
    }

    $result.TrailingComments = @($pendingComments)
    return $result
}

function ConvertTo-Psd1String {
    <#
    .SYNOPSIS
        Quotes a string as a single-quoted PowerShell data file literal.
    #>
    param([string]$Value)

    return "'" + ([string]$Value).Replace("'", "''") + "'"
}

function ConvertTo-AtlasArch {
    <#
    .SYNOPSIS
        Maps an AME cpuArch value to the tweak schema's Arch value.
    #>
    param([string]$CpuArch)

    switch (($CpuArch + '').ToUpperInvariant()) {
        'X64' { return 'X64' }
        'AMD64' { return 'X64' }
        'ARM64' { return 'ARM64' }
        default { return $null }
    }
}

function Convert-AmeTweak {
    <#
    .SYNOPSIS
        Maps parsed AME actions onto the Atlas tweak schema sections, collecting
        fidelity information (weights, dropped keys, unmapped constructs).
    #>
    param([pscustomobject]$Parse)

    $registryTypeMap = @{
        'REG_DWORD'     = 'DWord'
        'REG_SZ'        = 'String'
        'REG_EXPAND_SZ' = 'ExpandString'
        'REG_BINARY'    = 'Binary'
        'REG_MULTI_SZ'  = 'MultiString'
        'REG_QWORD'     = 'QWord'
        'REG_NONE'      = 'None'
    }

    $model = [pscustomobject]@{
        Name             = $Parse.Title
        Description      = $Parse.Description
        TopGates         = [ordered]@{}
        Sections         = [ordered]@{
            Registry       = New-Object System.Collections.Generic.List[object]
            Services       = New-Object System.Collections.Generic.List[object]
            ScheduledTasks = New-Object System.Collections.Generic.List[object]
            StopProcesses  = New-Object System.Collections.Generic.List[object]
            Run            = New-Object System.Collections.Generic.List[object]
            RemovePaths    = New-Object System.Collections.Generic.List[object]
        }
        TrailingComments = @($Parse.TrailingComments)
        ActionsIn        = $Parse.Actions.Count
        EntriesOut       = 0
        Unmapped         = New-Object System.Collections.Generic.List[string]
        Dropped          = New-Object System.Collections.Generic.List[string]
        Weights          = New-Object System.Collections.Generic.List[int]
    }

    foreach ($item in $Parse.Unparsed) { $model.Unmapped.Add($item) }

    foreach ($gate in $Parse.HeaderGates.Keys) {
        $gateValue = $Parse.HeaderGates[$gate]
        switch ($gate) {
            'onUpgrade' { $model.TopGates['OnUpgrade'] = @{ 'true' = 'Only'; 'false' = 'Skip' }[$gateValue.ToLowerInvariant()] }
            'oobe' { if ($gateValue -eq 'false') { $model.TopGates['Oobe'] = '$false' } else { $model.Unmapped.Add("Header gate 'oobe: $gateValue' has no schema equivalent.") } }
            'option' { $model.TopGates['Option'] = ConvertFrom-YamlScalar -Value $gateValue }
            default { $model.Unmapped.Add("Header gate '${gate}: $gateValue' has no schema equivalent.") }
        }
    }

    # Per-action option/onUpgrade/oobe gates can only be expressed file-wide; collect
    # them and hoist when uniform, otherwise report so the file gets split by hand.
    $optionGates = New-Object System.Collections.Generic.List[string]
    $upgradeGates = New-Object System.Collections.Generic.List[string]
    $oobeGates = New-Object System.Collections.Generic.List[string]

    foreach ($action in $Parse.Actions) {
        $props = $action.Props
        $entry = [ordered]@{}
        $section = $null

        if ($props.Contains('weight')) { $model.Weights.Add([int]$props['weight']) }
        foreach ($droppedKey in @('runas', 'exeDir')) {
            if ($props.Contains($droppedKey)) { $model.Dropped.Add("!$($action.Tag) '${droppedKey}: $($props[$droppedKey])' (engine context replaces it)") }
        }
        $optionGates.Add([string]$props['option'])
        $upgradeGates.Add([string]$props['onUpgrade'])
        $oobeGates.Add([string]$props['oobe'])

        $arch = $null
        if ($props.Contains('cpuArch')) { $arch = ConvertTo-AtlasArch -CpuArch $props['cpuArch'] }

        # Note: 'continue' inside a switch statement targets the switch, not the loop,
        # so unmappable actions clear $section and are filtered after the switch.
        switch ($action.Tag) {
            'registryValue' {
                $section = 'Registry'
                $entry['Path'] = $props['path']
                $entry['Name'] = $props['value']
                if (([string]$props['operation']).ToLowerInvariant() -eq 'delete') {
                    $entry['Operation'] = 'Delete'
                }
                else {
                    $regType = $registryTypeMap[[string]$props['type']]
                    if (-not $regType) {
                        $model.Unmapped.Add("registryValue '$($props['value'])' has unsupported type '$($props['type'])'.")
                        $section = $null
                        break
                    }
                    if ($regType -in @('Binary', 'MultiString')) {
                        $model.Unmapped.Add("registryValue '$($props['value'])' of type '$regType' needs hand-converted Data.")
                        $section = $null
                        break
                    }
                    $entry['Type'] = $regType
                    if ($regType -in @('DWord', 'QWord')) { $entry['Data'] = [long]$props['data'] } else { $entry['Data'] = [string]$props['data'] }
                }
                if ($arch) { $entry['Arch'] = $arch }
                if (([string]$props['ignoreErrors']).ToLowerInvariant() -eq 'true') { $entry['IgnoreErrors'] = $true }
            }
            'registryKey' {
                $section = 'Registry'
                $entry['Path'] = $props['path']
                if (([string]$props['operation']).ToLowerInvariant() -eq 'delete') { $entry['Operation'] = 'DeleteKey' } else { $entry['Operation'] = 'AddKey' }
                if ($arch) { $entry['Arch'] = $arch }
                if (([string]$props['ignoreErrors']).ToLowerInvariant() -eq 'true') { $entry['IgnoreErrors'] = $true }
            }
            'service' {
                $section = 'Services'
                $entry['Name'] = $props['name']
                $operation = ([string]$props['operation']).ToLowerInvariant()
                switch ($operation) {
                    'stop' { $entry['Operation'] = 'Stop' }
                    'start' { $entry['Operation'] = 'Start' }
                    default { $entry['StartupType'] = [int]$props['startup'] }
                }
                if ($props.Contains('ignoreErrors')) { $model.Dropped.Add("!service '$($props['name'])' ignoreErrors (engine already warns and continues)") }
            }
            'scheduledTask' {
                $section = 'ScheduledTasks'
                $entry['Path'] = $props['path']
                if (([string]$props['operation']).ToLowerInvariant() -eq 'enable') { $entry['Operation'] = 'Enable' }
                if ($props.Contains('ignoreErrors')) { $model.Dropped.Add("!scheduledTask '$($props['path'])' ignoreErrors (engine already warns and continues)") }
            }
            'taskKill' {
                $section = 'StopProcesses'
                $entry['Process'] = ([string]$props['name']) -replace '\.exe$', ''
            }
            'run' {
                $section = 'Run'
                $entry['Exe'] = $props['exe']
                if ($props.Contains('args')) { $entry['Args'] = $props['args'] }
                if ($arch) { $entry['Arch'] = $arch }
                if (([string]$props['ignoreErrors']).ToLowerInvariant() -eq 'true') { $entry['IgnoreErrors'] = $true }
                if (([string]$props['wait']).ToLowerInvariant() -eq 'false') { $entry['Wait'] = $false }
            }
            'cmd' {
                $section = 'Run'
                $command = [string]$props['command']
                if ($command -match '^"([^"]+\.cmd)"\s*(.*)$') {
                    # A directly invoked .cmd keeps its own path as the executable.
                    $entry['Exe'] = $Matches[1]
                    if ($Matches[2]) { $entry['Args'] = $Matches[2] }
                }
                else {
                    $entry['Exe'] = 'cmd.exe'
                    $entry['Args'] = "/c $command"
                }
                if ($arch) { $entry['Arch'] = $arch }
                if (([string]$props['ignoreErrors']).ToLowerInvariant() -eq 'true') { $entry['IgnoreErrors'] = $true }
                if (([string]$props['wait']).ToLowerInvariant() -eq 'false') { $entry['Wait'] = $false }
            }
            'file' {
                $section = 'RemovePaths'
                $entry['Path'] = ([string]$props['path']) -replace '%windir%', '{windir}'
                if ($arch) { $entry['Arch'] = $arch }
            }
            default {
                $model.Unmapped.Add("Action '!$($action.Tag)' has no schema mapping (hand-convert).")
                $section = $null
            }
        }

        if (-not $section) { continue }

        $model.Sections[$section].Add([pscustomobject]@{ Comments = @($action.Comments); Props = $entry })
        $model.EntriesOut++
    }

    foreach ($gateInfo in @(
            @{ Name = 'Option'; Values = $optionGates },
            @{ Name = 'OnUpgrade'; Values = $upgradeGates },
            @{ Name = 'Oobe'; Values = $oobeGates })) {
        $distinct = @($gateInfo.Values | Sort-Object -Unique)
        if ($distinct.Count -eq 1 -and $distinct[0]) {
            switch ($gateInfo.Name) {
                'Option' { $model.TopGates['Option'] = $distinct[0] }
                'OnUpgrade' { $model.TopGates['OnUpgrade'] = @{ 'true' = 'Only'; 'false' = 'Skip' }[$distinct[0].ToLowerInvariant()] }
                'Oobe' { $model.Unmapped.Add("Uniform per-action gate 'oobe: $($distinct[0])' needs review (schema Oobe only skips OOBE).") }
            }
        }
        elseif ($distinct.Count -gt 1) {
            $model.Unmapped.Add("Mixed per-action '$($gateInfo.Name)' gating - split the file by hand.")
        }
    }

    return $model
}

function Format-AtlasTweakEntry {
    <#
    .SYNOPSIS
        Renders one section entry as a single-line psd1 hashtable literal.
    #>
    param([System.Collections.Specialized.OrderedDictionary]$Props)

    $pairs = foreach ($key in $Props.Keys) {
        $value = $Props[$key]
        if ($value -is [bool]) { $rendered = if ($value) { '$true' } else { '$false' } }
        elseif ($value -is [int] -or $value -is [long]) { $rendered = [string]$value }
        elseif ($key -in @('Operation', 'Type', 'Arch') -or ($key -eq 'StartupType')) { $rendered = ConvertTo-Psd1String -Value $value }
        else { $rendered = ConvertTo-Psd1String -Value $value }
        "$key = $rendered"
    }

    return '@{ ' + ($pairs -join '; ') + ' }'
}

function Format-AtlasTweakPsd1 {
    <#
    .SYNOPSIS
        Renders the converted tweak model as .psd1 text.
    #>
    param([pscustomobject]$Model)

    $topKeys = New-Object System.Collections.Generic.List[object]
    $topKeys.Add(@('Name', (ConvertTo-Psd1String -Value $Model.Name)))
    if ($Model.Description) { $topKeys.Add(@('Description', (ConvertTo-Psd1String -Value $Model.Description))) }
    foreach ($gate in @('Option', 'Arch', 'OnUpgrade')) {
        if ($Model.TopGates.Contains($gate)) { $topKeys.Add(@($gate, (ConvertTo-Psd1String -Value $Model.TopGates[$gate]))) }
    }
    if ($Model.TopGates.Contains('Oobe')) { $topKeys.Add(@('Oobe', [string]$Model.TopGates['Oobe'])) }

    $sectionNames = @($Model.Sections.Keys | Where-Object { $Model.Sections[$_].Count -gt 0 })
    $keyWidth = 4 # 'Name'
    foreach ($pair in $topKeys) { if ($pair[0].Length -gt $keyWidth) { $keyWidth = $pair[0].Length } }
    foreach ($name in $sectionNames) { if ($name.Length -gt $keyWidth) { $keyWidth = $name.Length } }

    $builder = New-Object System.Text.StringBuilder
    $null = $builder.AppendLine('@{')
    foreach ($pair in $topKeys) {
        $null = $builder.AppendLine(('    {0} = {1}' -f $pair[0].PadRight($keyWidth), $pair[1]))
    }

    foreach ($name in $sectionNames) {
        $entries = $Model.Sections[$name]
        if ($name -eq 'StopProcesses') {
            $processes = @($entries | ForEach-Object { ConvertTo-Psd1String -Value $_.Props['Process'] })
            $null = $builder.AppendLine(('    {0} = @({1})' -f $name.PadRight($keyWidth), ($processes -join ', ')))
            continue
        }

        $null = $builder.AppendLine(('    {0} = @(' -f $name.PadRight($keyWidth)))
        foreach ($entry in $entries) {
            foreach ($comment in $entry.Comments) {
                $null = $builder.AppendLine("        $comment")
            }
            $null = $builder.AppendLine('        ' + (Format-AtlasTweakEntry -Props $entry.Props))
        }
        $null = $builder.AppendLine('    )')
    }

    foreach ($comment in $Model.TrailingComments) {
        $null = $builder.AppendLine("    $comment")
    }

    $null = $builder.AppendLine('}')
    return $builder.ToString()
}

$resolvedPath = (Resolve-Path -LiteralPath $Path).ProviderPath
$parse = Read-AmeTweakYaml -FilePath $resolvedPath
$model = Convert-AmeTweak -Parse $parse
$psd1Text = Format-AtlasTweakPsd1 -Model $model

if ($Destination) {
    $destinationDir = Split-Path -Path $Destination -Parent
    if ($destinationDir -and -not (Test-Path -LiteralPath $destinationDir)) {
        New-Item -Path $destinationDir -ItemType Directory -Force | Out-Null
    }
    [System.IO.File]::WriteAllText($Destination, $psd1Text)
}
else {
    $psd1Text
}

$report = [pscustomobject]@{
    Path       = $resolvedPath
    ActionsIn  = $model.ActionsIn
    EntriesOut = $model.EntriesOut
    Unmapped   = @($model.Unmapped)
    Dropped    = @($model.Dropped)
    Weights    = @($model.Weights)
}

Write-Host ("[{0}] actions in: {1}, entries out: {2}" -f (Split-Path -Path $resolvedPath -Leaf), $report.ActionsIn, $report.EntriesOut)
foreach ($item in $report.Unmapped) { Write-Host "  UNMAPPED: $item" }
foreach ($item in $report.Dropped) { Write-Host "  dropped:  $item" }
foreach ($item in $report.Weights) { Write-Host "  weight:   $item" }

if ($PassThru) {
    $report
}
