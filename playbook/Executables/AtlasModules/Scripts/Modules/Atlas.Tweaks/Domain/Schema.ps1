# Atlas.Tweaks domain: tweak schema validation (used by CI and locally before builds).

$script:AtlasTweakTopLevelKeys = @(
    'Name', 'Description', 'Option', 'Arch', 'OnUpgrade', 'Oobe', 'RunAs', 'MinBuild', 'MaxBuild',
    'Registry', 'Services', 'ScheduledTasks', 'StopProcesses', 'Run', 'RemovePaths', 'Script'
)

$script:AtlasKnownOptions = @(
    'auto-updates-default', 'auto-updates-disable',
    'browser-brave', 'browser-chrome', 'browser-firefox', 'browser-librewolf',
    'defender-disable', 'defender-enable',
    'disable-core-isolation', 'disable-hibernation', 'disable-power-saving',
    'install-another-browser', 'install-toolbox',
    'mitigations-default', 'mitigations-disable',
    'remove-snipping-tool', 'uninstall-edge'
)

$script:AtlasRegistryValueTypes = @('String', 'ExpandString', 'Binary', 'DWord', 'MultiString', 'QWord', 'None')

function Test-AtlasTweakEntryList {
    <#
    .SYNOPSIS
        Validates that a tweak key holds a list of hashtables; returns them, reporting a
        problem (and returning an empty list) otherwise.
    #>
    param(
        [Parameter(Mandatory = $true)]
        [string]$FilePath,

        [Parameter(Mandatory = $true)]
        [string]$Key,

        [object]$Value,

        [Parameter(Mandatory = $true)]
        [AllowEmptyCollection()]
        [System.Collections.Generic.List[object]]$Problems
    )

    $entries = @()
    foreach ($item in @($Value)) {
        if ($item -is [hashtable]) {
            $entries += , $item
        }
        else {
            $Problems.Add([pscustomobject]@{ Path = $FilePath; Problem = "'$Key' entries must be hashtables." })
        }
    }

    return , $entries
}

function Test-AtlasTweakFileSchema {
    param(
        [Parameter(Mandatory = $true)]
        [string]$FilePath,

        [Parameter(Mandatory = $true)]
        [AllowEmptyCollection()]
        [System.Collections.Generic.List[object]]$Problems
    )

    function Add-Problem {
        param([string]$Problem)
        $Problems.Add([pscustomobject]@{ Path = $FilePath; Problem = $Problem })
    }

    $tweak = $null
    try {
        $tweak = Import-AtlasDataFile -LiteralPath $FilePath
    }
    catch {
        Add-Problem -Problem "File does not load as a PowerShell data file: $($_.Exception.Message)"
        return
    }

    foreach ($key in @($tweak.Keys)) {
        if ($key -notin $script:AtlasTweakTopLevelKeys) {
            Add-Problem -Problem "Unknown top-level key '$key'."
        }
    }

    if (-not $tweak.ContainsKey('Name') -or -not ($tweak['Name'] -is [string]) -or [string]::IsNullOrWhiteSpace($tweak['Name'])) {
        Add-Problem -Problem "Missing or empty 'Name' (required, non-empty string)."
    }

    if ($tweak.ContainsKey('Description') -and -not ($tweak['Description'] -is [string])) {
        Add-Problem -Problem "'Description' must be a string."
    }

    if ($tweak.ContainsKey('Option') -and $tweak['Option'] -notin $script:AtlasKnownOptions) {
        Add-Problem -Problem "Unknown 'Option' value '$($tweak['Option'])'."
    }

    if ($tweak.ContainsKey('Arch') -and $tweak['Arch'] -notin @('X64', 'ARM64')) {
        Add-Problem -Problem "'Arch' must be 'X64' or 'ARM64', got '$($tweak['Arch'])'."
    }

    if ($tweak.ContainsKey('OnUpgrade') -and $tweak['OnUpgrade'] -notin @('Skip', 'Only', 'Both')) {
        Add-Problem -Problem "'OnUpgrade' must be 'Skip', 'Only' or 'Both', got '$($tweak['OnUpgrade'])'."
    }

    if ($tweak.ContainsKey('Oobe') -and -not ($tweak['Oobe'] -is [bool])) {
        Add-Problem -Problem "'Oobe' must be a boolean."
    }

    foreach ($buildKey in @('MinBuild', 'MaxBuild')) {
        if ($tweak.ContainsKey($buildKey)) {
            $buildValue = $tweak[$buildKey]
            if (-not (($buildValue -is [int]) -or ($buildValue -is [long]))) {
                Add-Problem -Problem "'$buildKey' must be an integer Windows build number."
            }
        }
    }

    if ($tweak.ContainsKey('RunAs')) {
        if ($tweak['RunAs'] -notin @('User', 'UserElevated')) {
            Add-Problem -Problem "'RunAs' must be 'User' or 'UserElevated', got '$($tweak['RunAs'])'."
        }
        if (-not $tweak.ContainsKey('Script')) {
            Add-Problem -Problem "'RunAs' only applies to the 'Script' key, but no 'Script' is present."
        }
    }

    if ($tweak.ContainsKey('Registry')) {
        $entries = Test-AtlasTweakEntryList -FilePath $FilePath -Key 'Registry' -Value $tweak['Registry'] -Problems $Problems
        foreach ($entry in $entries) {
            $operation = 'Set'
            if ($entry.ContainsKey('Operation') -and $entry['Operation']) {
                $operation = [string]$entry['Operation']
            }

            if ($operation -notin @('Set', 'Delete', 'DeleteKey', 'AddKey')) {
                Add-Problem -Problem "Registry entry has an unknown Operation '$operation'."
                continue
            }

            if (-not $entry.ContainsKey('Path') -or [string]::IsNullOrWhiteSpace([string]$entry['Path'])) {
                Add-Problem -Problem 'Registry entry is missing its Path.'
            }

            if ($operation -in @('Set', 'Delete') -and (-not $entry.ContainsKey('Name') -or [string]::IsNullOrWhiteSpace([string]$entry['Name']))) {
                Add-Problem -Problem "Registry '$operation' entry is missing its Name."
            }

            if ($operation -eq 'Set') {
                if (-not $entry.ContainsKey('Type') -or $entry['Type'] -notin $script:AtlasRegistryValueTypes) {
                    Add-Problem -Problem "Registry 'Set' entry needs a Type of $($script:AtlasRegistryValueTypes -join ', ')."
                }
                elseif ($entry['Type'] -notin @('None', 'String', 'ExpandString') -and -not $entry.ContainsKey('Data')) {
                    Add-Problem -Problem "Registry 'Set' entry of type '$($entry['Type'])' is missing its Data."
                }
            }

            if ($entry.ContainsKey('Arch') -and $entry['Arch'] -notin @('X64', 'ARM64')) {
                Add-Problem -Problem "Registry entry 'Arch' must be 'X64' or 'ARM64'."
            }

            if ($entry.ContainsKey('IgnoreErrors') -and -not ($entry['IgnoreErrors'] -is [bool])) {
                Add-Problem -Problem "Registry entry 'IgnoreErrors' must be a boolean."
            }
        }
    }

    if ($tweak.ContainsKey('Services')) {
        $entries = Test-AtlasTweakEntryList -FilePath $FilePath -Key 'Services' -Value $tweak['Services'] -Problems $Problems
        foreach ($entry in $entries) {
            if (-not $entry.ContainsKey('Name') -or [string]::IsNullOrWhiteSpace([string]$entry['Name'])) {
                Add-Problem -Problem 'Service entry is missing its Name.'
            }

            $operation = 'Change'
            if ($entry.ContainsKey('Operation') -and $entry['Operation']) {
                $operation = [string]$entry['Operation']
            }

            if ($operation -notin @('Change', 'Stop', 'Start')) {
                Add-Problem -Problem "Service entry has an unknown Operation '$operation'."
            }
            elseif ($operation -eq 'Change') {
                if (-not $entry.ContainsKey('StartupType') -or -not ($entry['StartupType'] -is [int]) -or $entry['StartupType'] -lt 0 -or $entry['StartupType'] -gt 4) {
                    Add-Problem -Problem "Service 'Change' entry needs an integer StartupType between 0 and 4."
                }
            }
        }
    }

    if ($tweak.ContainsKey('ScheduledTasks')) {
        $entries = Test-AtlasTweakEntryList -FilePath $FilePath -Key 'ScheduledTasks' -Value $tweak['ScheduledTasks'] -Problems $Problems
        foreach ($entry in $entries) {
            if (-not $entry.ContainsKey('Path') -or [string]::IsNullOrWhiteSpace([string]$entry['Path'])) {
                Add-Problem -Problem 'ScheduledTasks entry is missing its Path.'
            }

            if ($entry.ContainsKey('Operation') -and $entry['Operation'] -notin @('Disable', 'Enable')) {
                Add-Problem -Problem "ScheduledTasks entry has an unknown Operation '$($entry['Operation'])'."
            }
        }
    }

    if ($tweak.ContainsKey('StopProcesses')) {
        foreach ($processName in @($tweak['StopProcesses'])) {
            if (-not ($processName -is [string]) -or [string]::IsNullOrWhiteSpace($processName)) {
                Add-Problem -Problem "'StopProcesses' entries must be non-empty process name strings."
            }
        }
    }

    if ($tweak.ContainsKey('Run')) {
        $entries = Test-AtlasTweakEntryList -FilePath $FilePath -Key 'Run' -Value $tweak['Run'] -Problems $Problems
        foreach ($entry in $entries) {
            if (-not $entry.ContainsKey('Exe') -or [string]::IsNullOrWhiteSpace([string]$entry['Exe'])) {
                Add-Problem -Problem 'Run entry is missing its Exe.'
            }

            if ($entry.ContainsKey('Arch') -and $entry['Arch'] -notin @('X64', 'ARM64')) {
                Add-Problem -Problem "Run entry 'Arch' must be 'X64' or 'ARM64'."
            }

            if ($entry.ContainsKey('Wait') -and -not ($entry['Wait'] -is [bool])) {
                Add-Problem -Problem "Run entry 'Wait' must be a boolean."
            }

            if ($entry.ContainsKey('IgnoreErrors') -and -not ($entry['IgnoreErrors'] -is [bool])) {
                Add-Problem -Problem "Run entry 'IgnoreErrors' must be a boolean."
            }
        }
    }

    if ($tweak.ContainsKey('RemovePaths')) {
        $entries = Test-AtlasTweakEntryList -FilePath $FilePath -Key 'RemovePaths' -Value $tweak['RemovePaths'] -Problems $Problems
        foreach ($entry in $entries) {
            if (-not $entry.ContainsKey('Path') -or [string]::IsNullOrWhiteSpace([string]$entry['Path'])) {
                Add-Problem -Problem 'RemovePaths entry is missing its Path.'
            }

            if ($entry.ContainsKey('Arch') -and $entry['Arch'] -notin @('X64', 'ARM64')) {
                Add-Problem -Problem "RemovePaths entry 'Arch' must be 'X64' or 'ARM64'."
            }
        }
    }

    if ($tweak.ContainsKey('Script')) {
        if (-not ($tweak['Script'] -is [string]) -or [string]::IsNullOrWhiteSpace($tweak['Script'])) {
            Add-Problem -Problem "'Script' must be a non-empty relative path string."
        }
        else {
            $companionPath = Join-Path -Path (Split-Path -Path $FilePath -Parent) -ChildPath $tweak['Script']
            if (-not (Test-Path -LiteralPath $companionPath -PathType Leaf)) {
                Add-Problem -Problem "Companion script '$($tweak['Script'])' does not exist next to the tweak file."
            }
        }
    }
}

function Test-AtlasTweakSchema {
    <#
    .SYNOPSIS
        Validates one tweak .psd1 file or every tweak file under a directory
        (recursively, excluding tweaks.manifest.psd1). Returns one problem record
        (Path + Problem) per issue; an empty result means everything validated.
    #>
    param(
        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [string]$Path
    )

    $files = @()
    if (Test-Path -LiteralPath $Path -PathType Container) {
        $files = @(Get-ChildItem -LiteralPath $Path -Filter '*.psd1' -Recurse -File |
            Where-Object { $_.Name -ne 'tweaks.manifest.psd1' })
    }
    elseif (Test-Path -LiteralPath $Path -PathType Leaf) {
        $files = @(Get-Item -LiteralPath $Path)
    }
    else {
        throw "Tweak schema validation target not found: '$Path'."
    }

    $problems = New-Object System.Collections.Generic.List[object]
    foreach ($file in $files) {
        Test-AtlasTweakFileSchema -FilePath $file.FullName -Problems $problems
    }

    # .ToArray() instead of @(...): the PS 5.1 array subexpression binder chokes on
    # generic lists here ("Argument types do not match").
    return $problems.ToArray()
}
