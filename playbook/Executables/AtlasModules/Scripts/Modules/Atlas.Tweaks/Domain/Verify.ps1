# Atlas.Tweaks domain: verification of applied tweaks.
#
# Test-AtlasTweak reads a tweak's Registry, Services and ScheduledTasks declarations back
# for one registry scope and reports what no longer holds. Run, RemovePaths, Toggle and
# companion scripts are imperative and are not verified here; Toggle entries are
# covered by the toggle engine's own verification.

function Test-AtlasTweak {
    <#
    .SYNOPSIS
        Returns the drift of one tweak's declarative entries, or nothing when the tweak
        does not apply to the given context.
    .OUTPUTS
        One object per drifted declaration: Tweak, Kind, Target, Reason.
    #>
    param(
        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [string]$Path,

        [ValidateSet('Machine', 'CurrentUser')]
        [string]$RegistryScope = 'Machine',

        [psobject]$Context,

        [System.Collections.IDictionary]$RecordedToggleStates = @{}
    )

    if (-not (Test-Path -LiteralPath $Path -PathType Leaf)) {
        throw "Tweak file not found: '$Path'."
    }
    $tweak = Import-AtlasDataFile -LiteralPath $Path
    $tweakName = [string]$tweak['Name']
    if (-not $PSBoundParameters.ContainsKey('Context')) {
        $Context = Get-AtlasContext
    }
    if ($null -ne (Get-AtlasTweakSkipReason -Tweak $tweak -Context $Context)) {
        return @()
    }

    $drift = @()
    if ($tweak.ContainsKey('Registry') -and $tweak['Registry']) {
        $verificationEntries = foreach ($entry in $tweak['Registry']) {
            # Install defaults remain unchanged. Only the read-back expectation changes
            # when a declared toggle override has actually been recorded. Current-user
            # entries are still read from the account being verified, never another hive.
            $expected = ([hashtable]$entry).Clone()
            if ($entry.ContainsKey('VerifyWithToggle')) {
                $override = $entry['VerifyWithToggle']
                if ($RecordedToggleStates.Contains($override['Name']) -and
                    [int]$RecordedToggleStates[$override['Name']] -eq [int]$override['State']) {
                    foreach ($key in 'Operation', 'Type', 'Data') { $expected.Remove($key) }
                    foreach ($key in 'Operation', 'Type', 'Data') {
                        if ($override.ContainsKey($key)) { $expected[$key] = $override[$key] }
                    }
                }
            }
            $expected
        }
        # Toggle verification checks the chosen state's declarations. Unlocked
        # preferences have no fixed install-default expectation.
        $verificationEntries = @(Get-AtlasUpgradeRegistryEntries -Entries @($verificationEntries) -Records $RecordedToggleStates -IgnoreInvalidDefinitions)
        foreach ($item in @(Test-AtlasRegistryEntries -Entries @($verificationEntries) -Scope $RegistryScope -IsArm64 ([bool]$Context.IsArm64))) {
            $drift += [pscustomobject]@{ Tweak = $tweakName; Kind = 'Registry'; Target = "$($item.Path)\$($item.Name)"; Reason = $item.Reason }
        }
    }
    if ($RegistryScope -ceq 'Machine') {
        if ($tweak.ContainsKey('Services') -and $tweak['Services']) {
            foreach ($item in @(Test-AtlasServiceEntries -Entries $tweak['Services'])) {
                $drift += [pscustomobject]@{ Tweak = $tweakName; Kind = 'Service'; Target = $item.Service; Reason = "$($item.Reason) (expected $($item.Expected), found $($item.Actual))" }
            }
        }
        if ($tweak.ContainsKey('ScheduledTasks') -and $tweak['ScheduledTasks']) {
            foreach ($item in @(Test-AtlasScheduledTaskEntries -Entries $tweak['ScheduledTasks'])) {
                $drift += [pscustomobject]@{ Tweak = $tweakName; Kind = 'ScheduledTask'; Target = $item.Task; Reason = "$($item.Reason) (expected $($item.Expected), found $($item.Actual))" }
            }
        }
    }
    return $drift
}

function Test-AtlasTweakCategory {
    <#
    .SYNOPSIS
        Returns the drift of every enabled tweak in a manifest category.
    #>
    param(
        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [string]$Name,

        [string]$TweaksRoot,

        [ValidateSet('Machine', 'CurrentUser')]
        [string]$RegistryScope = 'Machine',

        [psobject]$Context,

        [System.Collections.IDictionary]$RecordedToggleStates = @{}
    )

    if ($null -eq $Context) {
        $Context = Get-AtlasContext
    }
    if (-not $TweaksRoot) {
        $TweaksRoot = Join-Path -Path $Context.AtlasModulesPath -ChildPath 'Scripts\Tweaks'
    }
    $manifest = Get-AtlasTweakManifest -Path (Join-Path -Path $TweaksRoot -ChildPath 'tweaks.manifest.psd1')
    $category = $manifest['Categories'] | Where-Object { [string]$_['Name'] -ceq $Name } | Select-Object -First 1
    if ($null -eq $category) {
        throw "Category '$Name' is not defined in the tweak manifest."
    }

    $drift = @()
    foreach ($tweakName in @($category['Tweaks'])) {
        $tweakFile = Join-Path -Path (Join-Path -Path $TweaksRoot -ChildPath $Name) -ChildPath (([string]$tweakName -replace '/', '\') + '.psd1')
        $drift += @(Test-AtlasTweak -Path $tweakFile -RegistryScope $RegistryScope -Context $Context -RecordedToggleStates $RecordedToggleStates)
    }
    return $drift
}
