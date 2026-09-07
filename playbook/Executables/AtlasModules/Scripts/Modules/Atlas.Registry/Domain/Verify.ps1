# Atlas.Registry domain: verification of declarative registry entries.
#
# Apply and verify share one vocabulary. Invoke-AtlasRegistryEntries applies a Registry
# array; Test-AtlasRegistryEntries reads the same array back and reports every entry
# whose current value differs from what it declares. The health check, the upgrade
# reconciliation report and tests use it; it never writes.

function Get-AtlasRegistryValueState {
    <#
    .SYNOPSIS
        Reads one value (or key) through the same identity-scoped resolution that
        writes use, without expanding environment strings.
    .OUTPUTS
        KeyExists, ValueExists, Kind and Data.
    #>
    param(
        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [string]$Path,

        [AllowEmptyString()]
        [string]$Name = ''
    )

    $state = [pscustomobject]@{ KeyExists = $false; ValueExists = $false; Kind = $null; Data = $null }
    Invoke-AtlasRegistryTargetOperation -Path $Path -Action {
        param($providerPath)

        $split = Split-AtlasRegistryProviderPath -ProviderPath $providerPath
        $key = $split.BaseKey.OpenSubKey($split.SubPath, $false)
        if ($null -eq $key) {
            return
        }
        try {
            $state.KeyExists = $true
            if (@($key.GetValueNames()) -contains $Name) {
                $state.ValueExists = $true
                $state.Kind = [string]$key.GetValueKind($Name)
                $state.Data = $key.GetValue($Name, $null, [Microsoft.Win32.RegistryValueOptions]::DoNotExpandEnvironmentNames)
            }
        }
        finally {
            $key.Close()
        }
    }
    return $state
}

function Test-AtlasRegistryDataEqual {
    param(
        [Parameter(Mandatory = $true)][string]$Type,
        [object]$Expected,
        [object]$Actual
    )

    switch ($Type) {
        'DWord' { return [int64](ConvertTo-AtlasDwordData -Data $Expected) -eq [int64]$Actual }
        'QWord' { return [int64](ConvertTo-AtlasQwordData -Data $Expected) -eq [int64]$Actual }
        'Binary' {
            $left = [byte[]]$Expected
            $right = [byte[]]$Actual
            if ($left.Length -ne $right.Length) { return $false }
            for ($index = 0; $index -lt $left.Length; $index++) {
                if ($left[$index] -ne $right[$index]) { return $false }
            }
            return $true
        }
        'MultiString' {
            $left = @([string[]]$Expected)
            $right = @([string[]]$Actual)
            if ($left.Count -ne $right.Count) { return $false }
            for ($index = 0; $index -lt $left.Count; $index++) {
                if ($left[$index] -cne $right[$index]) { return $false }
            }
            return $true
        }
        'None' { return $true }
        default { return [string]$Expected -ceq [string]$Actual }
    }
}

function Test-AtlasRegistryEntries {
    <#
    .SYNOPSIS
        Reports every Registry entry whose current state differs from its declaration.
        Scope selects the same subset Invoke-AtlasRegistryEntries would apply.
    .OUTPUTS
        One object per drifted entry: Path, Name, Operation, Expected, Actual, Reason.
    #>
    param(
        [Parameter(Mandatory = $true)]
        [AllowEmptyCollection()]
        [hashtable[]]$Entries,

        [ValidateSet('All', 'Machine', 'ProtectedCurrentUser', 'CurrentUser', 'DefaultUser')]
        [string]$Scope = 'All',

        [bool]$IsArm64
    )

    $arm64 = if ($PSBoundParameters.ContainsKey('IsArm64')) { $IsArm64 } else { [bool](Get-AtlasContext).IsArm64 }
    $drift = @()

    foreach ($entry in $Entries) {
        if (-not $entry.ContainsKey('Path') -or [string]::IsNullOrWhiteSpace([string]$entry['Path'])) {
            continue
        }
        $targetScope = Get-AtlasRegistryEntryTargetScope -Path ([string]$entry['Path'])
        $appliesToScope = switch ($Scope) {
            'All' { $true }
            'Machine' { $targetScope -ceq 'Machine' }
            'ProtectedCurrentUser' { $targetScope -ceq 'ProtectedCurrentUser' }
            'CurrentUser' { $targetScope -ceq 'CurrentUser' }
            'DefaultUser' { $targetScope -in @('CurrentUser', 'ProtectedCurrentUser', 'DefaultUser') }
        }
        if (-not $appliesToScope) {
            continue
        }
        $arch = if ($entry.ContainsKey('Arch')) { [string]$entry['Arch'] } else { '' }
        if (-not (Test-AtlasArchMatch -Arch $arch -IsArm64 $arm64)) {
            continue
        }

        if ($entry.ContainsKey('SkipVerification')) {
            if ($entry['SkipVerification'] -isnot [string] -or
                [string]::IsNullOrWhiteSpace($entry['SkipVerification'])) {
                throw "Registry entry 'SkipVerification' must be a non-empty reason string."
            }
            Write-Verbose "Skipping registry verification for '$($entry['Path'])': $($entry['SkipVerification'])"
            continue
        }

        $operation = 'Set'
        if ($entry.ContainsKey('Operation') -and $entry['Operation']) {
            $operation = [string]$entry['Operation']
        }
        $name = if ($entry.ContainsKey('Name')) { [string]$entry['Name'] } else { '' }
        $path = [string]$entry['Path']

        try {
            $actual = Get-AtlasRegistryValueState -Path $path -Name $name
        }
        catch {
            $drift += [pscustomobject]@{
                Path = $path; Name = $name; Operation = $operation
                Expected = $null; Actual = $null; Reason = "could not be read: $($_.Exception.Message)"
            }
            continue
        }

        $reason = $null
        switch ($operation) {
            'Set' {
                $type = [string]$entry['Type']
                if (-not $actual.ValueExists) {
                    $reason = 'value is missing'
                }
                elseif ($type -cne 'None' -and $actual.Kind -cne $type) {
                    $reason = "value kind is $($actual.Kind), expected $type"
                }
                elseif ($entry.ContainsKey('Mask')) {
                    try {
                        $merged = Merge-AtlasRegistryMaskedData -Entry $entry -Current $actual.Data
                        if (-not (Test-AtlasRegistryDataEqual -Type $type -Expected $merged -Actual $actual.Data)) { $reason = 'selected value bits differ' }
                    }
                    catch { $reason = $_.Exception.Message }
                }
                elseif (-not (Test-AtlasRegistryDataEqual -Type $type -Expected $entry['Data'] -Actual $actual.Data)) {
                    $reason = 'value data differs'
                }
            }
            'Delete' { if ($actual.ValueExists) { $reason = 'value still exists' } }
            'DeleteKey' { if ($actual.KeyExists) { $reason = 'key still exists' } }
            'AddKey' { if (-not $actual.KeyExists) { $reason = 'key is missing' } }
            default { $reason = "unknown operation '$operation'" }
        }

        if ($null -ne $reason) {
            $drift += [pscustomobject]@{
                Path = $path; Name = $name; Operation = $operation
                Expected = if ($entry.ContainsKey('Data')) { $entry['Data'] } else { $null }
                Actual = $actual.Data; Reason = $reason
            }
        }
    }

    return $drift
}
