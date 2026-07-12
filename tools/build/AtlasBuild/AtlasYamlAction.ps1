Set-StrictMode -Version 3.0
function Split-AtlasYamlFlow {
    param([Parameter(Mandatory = $true)][string]$Text,
        [Parameter(Mandatory = $true)][char]$Separator)
    $parts = [Collections.Generic.List[string]]::new()
    $start = 0
    $depth = 0
    $quote = [char]0
    for ($index = 0; $index -lt $Text.Length; $index++) {
        $character = $Text[$index]
        if ($quote -ne [char]0) {
            if ($character -eq $quote) {
                if ($quote -eq [char]39 -and $index + 1 -lt $Text.Length -and
                    $Text[$index + 1] -eq [char]39) {
                    $index++
                }
                else {
                    $quote = [char]0
                }
            }
            continue
        }
        if ($character -eq [char]39 -or $character -eq [char]34) {
            $quote = $character
            continue
        }
        if ($character -eq '{' -or $character -eq '[') { $depth++; continue }
        if ($character -eq '}' -or $character -eq ']') { $depth--; continue }
        if ($character -eq $Separator -and $depth -eq 0) {
            $parts.Add($Text.Substring($start, $index - $start).Trim())
            $start = $index + 1
        }
    }
    if ($quote -ne [char]0 -or $depth -ne 0) {
        throw 'Atlas YAML flow value has an unterminated quote or container.'
    }
    $parts.Add($Text.Substring($start).Trim())
    return $parts.ToArray()
}
function ConvertFrom-AtlasYamlValue {
    param(
        [Parameter(Mandatory = $true)][AllowEmptyString()][string]$Text,
        [ValidateRange(0, 2)][int]$ContainerDepth = 0
    )
    $value = $Text.Trim()
    if ($value.Length -eq 0) { throw 'Atlas YAML values must not be empty.' }
    if ($value[0] -eq [char]39) {
        if ($value.Length -lt 2 -or $value[$value.Length - 1] -ne [char]39) {
            throw 'Atlas YAML has an incomplete single-quoted value.' }
        return $value.Substring(1, $value.Length - 2).Replace("''", "'")
    }
    if ($value[0] -eq [char]34) {
        if ($value.Length -lt 2 -or $value[$value.Length - 1] -ne [char]34) {
            throw 'Atlas YAML has an incomplete double-quoted value.' }
        return $value.Substring(1, $value.Length - 2)
    }
    if ($value[0] -eq '{') {
        if ($ContainerDepth -ge 2) { throw 'Atlas YAML supports only shallow flow containers.' }
        if ($value[$value.Length - 1] -ne '}') {
            throw 'Atlas YAML flow map is missing its closing brace.' }
        $map = [ordered]@{}
        $inner = $value.Substring(1, $value.Length - 2).Trim()
        if ($inner.Length -eq 0) { return $map }
        foreach ($entry in @(Split-AtlasYamlFlow -Text $inner -Separator ',')) {
            $pair = @(Split-AtlasYamlFlow -Text $entry -Separator ':')
            if ($pair.Count -ne 2) { throw "Atlas YAML flow entry '$entry' is not key/value data." }
            $key = [string](ConvertFrom-AtlasYamlValue -Text $pair[0])
            if ($key -notmatch '^[A-Za-z][A-Za-z0-9]*$|^!0$') {
                throw "Atlas YAML property '$key' is unsupported." }
            if ($map.Contains($key)) { throw "Duplicate Atlas YAML property '$key'." }
            $map[$key] = ConvertFrom-AtlasYamlValue -Text $pair[1] `
                -ContainerDepth ($ContainerDepth + 1)
        }
        return $map
    }
    if ($value[0] -eq '[') {
        if ($ContainerDepth -ge 2) { throw 'Atlas YAML supports only shallow flow containers.' }
        if ($value[$value.Length - 1] -ne ']') {
            throw 'Atlas YAML flow list is missing its closing bracket.' }
        $inner = $value.Substring(1, $value.Length - 2).Trim()
        if ($inner.Length -eq 0) { return ,@() }
        $items = @(Split-AtlasYamlFlow -Text $inner -Separator ',' | ForEach-Object {
                ConvertFrom-AtlasYamlValue -Text $_ `
                    -ContainerDepth ($ContainerDepth + 1)
            })
        return ,$items
    }
    if ($value -ceq 'true') { return $true }
    if ($value -ceq 'false') { return $false }
    if ($value -match '^-?[0-9]+$') {
        $number = 0
        if (-not [int]::TryParse($value, [ref]$number)) {
            throw "Atlas YAML integer '$value' is invalid." }
        return $number
    }
    if ($value -notmatch '^[A-Za-z][A-Za-z0-9_-]*$') {
        throw "Atlas YAML value '$value' must be quoted." }
    return $value
}
function Get-AtlasYamlAction {
    [CmdletBinding(DefaultParameterSetName = 'Path')]
    param(
        [Parameter(Mandatory = $true, ParameterSetName = 'Path')][string]$Path,
        [Parameter(Mandatory = $true, ParameterSetName = 'Text')][string]$Text,
        [string]$RelativePath
    )
    $resolvedPath = $null
    if ($PSCmdlet.ParameterSetName -eq 'Path') {
        $resolvedPath = (Resolve-Path -LiteralPath $Path).ProviderPath
        $Text = [IO.File]::ReadAllText($resolvedPath)
        if ([string]::IsNullOrWhiteSpace($RelativePath)) { $RelativePath = $resolvedPath }
    }
    elseif ([string]::IsNullOrWhiteSpace($RelativePath)) {
        $RelativePath = '<memory>'
    }
    $lines = @([regex]::Split($Text, '\r?\n'))
    $actionsKeys = @(for ($index = 0; $index -lt $lines.Count; $index++) {
            if ($lines[$index] -match '^actions:\s*$') { $index }
        })
    if ($actionsKeys.Count -ne 1) {
        throw "YAML '$RelativePath' must contain exactly one root actions key."
    }
    $starts = [Collections.Generic.List[int]]::new()
    for ($index = $actionsKeys[0] + 1; $index -lt $lines.Count; $index++) {
        if ($lines[$index] -match '^  - ' -and
            $lines[$index] -notmatch '^  - ![A-Za-z][A-Za-z0-9]*:') {
            throw "YAML '$RelativePath' has an unsupported action header at line $($index + 1)."
        }
        if ($lines[$index] -match '^  - ![A-Za-z][A-Za-z0-9]*:') { $starts.Add($index) }
    }
    for ($ordinal = 0; $ordinal -lt $starts.Count; $ordinal++) {
        $start = $starts[$ordinal]
        $end = if ($ordinal + 1 -lt $starts.Count) { $starts[$ordinal + 1] } else { $lines.Count }
        $null = $lines[$start] -match '^  - !(?<Type>[A-Za-z][A-Za-z0-9]*):(?<Payload>.*)$'
        $type = $Matches.Type
        $payload = $Matches.Payload.Trim()
        $properties = [ordered]@{}
        if ($payload.Length -gt 0) {
            $properties = ConvertFrom-AtlasYamlValue -Text $payload
            if ($properties -isnot [Collections.IDictionary]) {
                throw "YAML '$RelativePath' action at line $($start + 1) needs a flow map."
            }
        }
        else {
            for ($lineIndex = $start + 1; $lineIndex -lt $end; $lineIndex++) {
                $line = $lines[$lineIndex]
                if ([string]::IsNullOrWhiteSpace($line) -or $line -match '^\s*#') { continue }
                if ($line -notmatch '^    (?<Name>[A-Za-z][A-Za-z0-9]*):\s*(?<Value>.+?)\s*$') {
                    throw "YAML '$RelativePath' action at line $($start + 1) has unsupported content."
                }
                if ($properties.Contains($Matches.Name)) {
                    throw "YAML '$RelativePath' action at line $($start + 1) has duplicate property '$($Matches.Name)'."
                }
                $properties[$Matches.Name] = ConvertFrom-AtlasYamlValue -Text $Matches.Value
            }
        }
        [pscustomobject]@{
            File = $resolvedPath; RelativePath = $RelativePath; Line = $start + 1
            Type = $type; Text = $lines[$start..($end - 1)] -join "`n"
            Properties = $properties; DocumentProperties = [ordered]@{}
        }
    }
}
function ConvertTo-AtlasYamlCanonicalValue {
    param([AllowNull()]$Value)
    if ($null -eq $Value) { return 'null' }
    if ($Value -is [bool]) { return 'bool:' + $Value.ToString().ToLowerInvariant() }
    if ($Value -is [int]) { return 'int:' + $Value.ToString() }
    if ($Value -is [Collections.IDictionary]) {
        $entries = foreach ($key in @($Value.Keys | Sort-Object)) {
            $text = [string]$key
            '{0}:{1}={2}' -f $text.Length, $text, (ConvertTo-AtlasYamlCanonicalValue $Value[$key])
        }
        return 'map:{' + ($entries -join ';') + '}'
    }
    if ($Value -is [Collections.IEnumerable] -and $Value -isnot [string]) {
        return 'array:[' + (@($Value | ForEach-Object {
                    ConvertTo-AtlasYamlCanonicalValue $_
                }) -join ';') + ']'
    }
    $text = [string]$Value
    return 'string:' + $text.Length + ':' + $text
}
function Get-AtlasConfigurationRunnerContract {
    [CmdletBinding()]
    param([Parameter(Mandatory = $true)][string]$ConfigurationRoot)
    $root = (Resolve-Path -LiteralPath $ConfigurationRoot).ProviderPath
    $files = @(Get-ChildItem -LiteralPath $root -Filter '*.yml' -File -Recurse |
            Sort-Object FullName)
    foreach ($file in $files) {
        $relativePath = $file.FullName.Substring($root.Length + 1) -replace '\\', '/'
        $runs = @(Get-AtlasYamlAction -Path $file.FullName -RelativePath $relativePath |
                Where-Object Type -eq run)
        for ($ordinal = 0; $ordinal -lt $runs.Count; $ordinal++) {
            $action = $runs[$ordinal]
            [pscustomobject]@{ RelativePath = $relativePath; Ordinal = $ordinal
                Line = $action.Line
                Signature = '{0}|type=3:run|run={1:D4}|properties={2}|document={3}' -f `
                    $relativePath, $ordinal,
                    (ConvertTo-AtlasYamlCanonicalValue $action.Properties),
                    (ConvertTo-AtlasYamlCanonicalValue $action.DocumentProperties)
            }
        }
    }
}
function Assert-AtlasConfigurationRunnerBoundary {
    [CmdletBinding()]
    param([Parameter(Mandatory = $true)][string]$ConfigurationRoot)
    $root = (Resolve-Path -LiteralPath $ConfigurationRoot).ProviderPath
    $variants = @(Get-ChildItem -LiteralPath $root -File -Recurse | Where-Object {
            $_.Extension -ieq '.yaml' -or
            ($_.Extension -ieq '.yml' -and $_.Extension -cne '.yml')
    })
    if ($variants.Count) {
        throw ('Configuration contains unreviewed YAML filename variants: ' +
            (($variants | ForEach-Object Name) -join ', '))
    }
    $files = @(Get-ChildItem -LiteralPath $root -Filter '*.yml' -File -Recurse)
    if ($files.Count -ne 1 -or $files[0].Name -cne 'custom.yml') {
        throw 'Configuration must contain exactly one reviewed custom.yml file.'
    }
    $actions = @(Get-AtlasYamlAction -Path $files[0].FullName -RelativePath 'custom.yml')
    $tasks = @($actions | Where-Object Type -eq task)
    if ($tasks.Count) { throw 'Configuration must contain zero AME !task actions.' }
    $retired = @($actions | Where-Object Type -in @('cmd', 'powerShell', 'taskKill', 'registryValue'))
    if ($retired.Count) {
        throw 'Configuration contains retired runner actions: ' +
            (($retired | ForEach-Object { "custom.yml:$($_.Line) !$($_.Type)" }) -join ', ')
    }
    if (@($actions | Where-Object Type -notin @('run', 'writeStatus', 'registryKey')).Count) {
        throw 'Configuration contains an unsupported action type.'
    }
    if ($actions.Count -ne 29) { throw "Configuration must contain 29 actions; found $($actions.Count)." }
    $registry = @($actions | Where-Object Type -eq registryKey)
    $expectedRegistry = ConvertTo-AtlasYamlCanonicalValue ([ordered]@{
            path = 'HKLM\OfflineSys\ControlSet001\Services\WdBoot'; operation = 'delete'
            option = 'defender-disable'; iso = 'only'; onUpgrade = $false
        })
    if ($registry.Count -ne 1 -or
        (ConvertTo-AtlasYamlCanonicalValue $registry[0].Properties) -cne $expectedRegistry) {
        throw 'Configuration !registryKey contract differs from the reviewed ISO-only WdBoot delete.'
    }
    $statuses = @($actions | Where-Object Type -eq writeStatus)
    if ($statuses.Count -ne 2 -or
        [string]$statuses[0].Properties.status -cne 'Preparing AtlasOS installation' -or
        [string]$statuses[1].Properties.status -cne 'Installing AtlasOS' -or
        @($statuses | Where-Object { $_.Properties.Count -ne 1 }).Count) {
        throw 'Configuration must contain only the two reviewed coarse status actions.'
    }
    $runs = @($actions | Where-Object Type -eq run)
    if ($runs.Count -ne 26) { throw "Configuration must contain 26 runs; found $($runs.Count)." }
    $hostPath = '%SystemRoot%\System32\WindowsPowerShell\v1.0\powershell.exe'
    $prefix = '-NoLogo -NoProfile -NonInteractive -ExecutionPolicy Bypass'
    $statePrefix = $prefix + ' -File ".\AtlasModules\Scripts\Initialize-AtlasInstallState.ps1"'
    $publisherArgs = $prefix + ' -File ".\AtlasModules\Scripts\Publish-AtlasInstallUser.ps1"'
    $installArgs = $prefix + ' -File ".\AtlasModules\Scripts\Invoke-AtlasInstall.ps1" -Run'
    $commonNames = @('exe', 'args', 'runas', 'showOutput', 'showError', 'exeDir',
        'wait', 'weight', 'handleExitCodes')
    $allowedNames = $commonNames + @('onUpgrade', 'onUpgradeVersions', 'oobe', 'option')
    $publisherCount = 0; $commitCount = 0; $installCount = 0
    $beginKeys = [Collections.Generic.HashSet[string]]::new([StringComparer]::Ordinal)
    $options = [Collections.Generic.HashSet[string]]::new([StringComparer]::Ordinal)
    $reapplyVersions = [Collections.Generic.HashSet[string]]::new([StringComparer]::Ordinal)
    foreach ($action in $runs) {
        $properties = $action.Properties
        foreach ($name in $commonNames) {
            if (-not $properties.Contains($name)) { throw "custom.yml:$($action.Line) !run is missing required '$name'." }
        }
        if (@($properties.Keys | Where-Object { $allowedNames -cnotcontains $_ }).Count) {
            throw "custom.yml:$($action.Line) !run contains an unsupported field."
        }
        if ([string]$properties.exe -cne $hostPath) {
            throw "custom.yml:$($action.Line) !run does not use the exact Windows PowerShell host."
        }
        foreach ($name in @('showOutput', 'showError', 'exeDir', 'wait')) {
            if ($properties[$name] -isnot [bool] -or -not $properties[$name]) {
                throw "custom.yml:$($action.Line) !run must set $name to true."
            }
        }
        if ($properties.weight -isnot [int] -or $properties.weight -ne 1) {
            throw "custom.yml:$($action.Line) !run must use weight 1."
        }
        $exitMap = $properties.handleExitCodes
        if ($exitMap -isnot [Collections.IDictionary] -or $exitMap.Count -ne 1 -or
            [string]$exitMap['!0'] -cne 'halt') {
            throw "custom.yml:$($action.Line) !run must halt on every nonzero exit code."
        }
        $arguments = [string]$properties.args
        if (-not $arguments.StartsWith($prefix + ' -File "', [StringComparison]::Ordinal)) {
            throw "custom.yml:$($action.Line) !run must use direct File mode."
        }
        if ([string]$properties.runas -ceq 'currentUser') {
            $publisherCount++
            if ($arguments -cne $publisherArgs -or $properties.Count -ne 10 -or
                $properties.oobe -isnot [bool] -or $properties.oobe) {
                throw 'runas currentUser is reserved for the exact non-OOBE Publish-AtlasInstallUser.ps1 action.'
            }
            continue
        }
        if ([string]$properties.runas -cne 'trustedInstaller') {
            throw "custom.yml:$($action.Line) !run has unsupported runas '$($properties.runas)'."
        }
        if ($arguments -ceq $statePrefix + ' -Operation Commit') {
            $commitCount++; if ($properties.Count -ne 9) { throw 'Commit has unsupported gates.' }
            continue
        }
        if ($arguments -ceq $installArgs) {
            $installCount++; if ($properties.Count -ne 9) { throw 'Install run has unsupported gates.' }
            continue
        }
        if ($arguments -match ('^' + [regex]::Escape($statePrefix) +
                ' -Operation RecordOption -Option (?<Option>[a-z0-9-]+)$')) {
            if ($properties.Count -ne 10 -or
                [string]$properties.option -cne $Matches.Option -or
                -not $options.Add($Matches.Option)) {
                throw 'Option capture is duplicated or does not match its AME gate.'
            }
            continue
        }
        if ($arguments -match ('^' + [regex]::Escape($statePrefix) +
                ' -Operation Begin -Mode (?<Mode>Fresh|Upgrade|Reapply)(?<Oobe> -Oobe)?$')) {
            $modeMatch = $Matches
            $isOobe = $modeMatch.ContainsKey('Oobe')
            $key = $modeMatch.Mode + '|' + $isOobe.ToString()
            if (-not $beginKeys.Add($key)) { throw "Duplicate install mode '$key'." }
            $expectedOobe = if ($isOobe) { 'only' } else { $false }
            if ($properties.oobe -ne $expectedOobe) { throw "Install mode '$key' has the wrong OOBE gate." }
            $expectedUpgrade = $modeMatch.Mode -cne 'Fresh'
            if ($properties.onUpgrade -ne $expectedUpgrade) { throw "Install mode '$key' has the wrong upgrade gate." }
            if ($modeMatch.Mode -ceq 'Reapply') {
                if ($properties.Count -ne 12 -or @($properties.onUpgradeVersions).Count -ne 1) {
                    throw "Install mode '$key' needs one reapply version."
                }
                $null = $reapplyVersions.Add([string]@($properties.onUpgradeVersions)[0])
            }
            elseif ($properties.Count -ne 11 -or $properties.Contains('onUpgradeVersions')) {
                throw "Install mode '$key' has unsupported version gates."
            }
            continue
        }
        throw "custom.yml:$($action.Line) targets an unsupported PowerShell operation."
    }
    if ($publisherCount -ne 1 -or $commitCount -ne 1 -or $installCount -ne 1 -or
        $beginKeys.Count -ne 6 -or $options.Count -ne 17 -or $reapplyVersions.Count -ne 1) {
        throw 'Configuration runner operation counts differ from the compact Atlas contract.'
    }
    return [pscustomobject]@{ Files = 1; Actions = $actions.Count; Runs = $runs.Count
        RequiresTrustedRunnerEnvironment = $true }
}
