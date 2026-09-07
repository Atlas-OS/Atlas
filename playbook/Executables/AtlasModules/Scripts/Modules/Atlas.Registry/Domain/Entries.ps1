# Merge only explicitly selected bits; reject unexpected formats instead of resetting preferences.
function Merge-AtlasRegistryMaskedData {
    param([Parameter(Mandatory = $true)][hashtable]$Entry, [object]$Current)
    if ($Entry.ContainsKey('Operation') -and $Entry.Operation -cne 'Set') { throw 'Mask requires a Set entry.' }
    if ($Entry.ContainsKey('UseGroupPolicy') -and $Entry.UseGroupPolicy) { throw 'Mask cannot use Group Policy.' }
    if ($Entry.Type -ceq 'Binary') {
        [byte[]]$mask = $Entry.Mask
        [byte[]]$desired = $Entry.Data
        if ($mask.Length -eq 0 -or $mask.Length -ne $desired.Length) { throw 'Binary Mask and Data must have the same nonzero length.' }
        if ($null -eq $Current) { return ,$desired }
        if ($Current -isnot [byte[]] -or $Current.Length -ne $mask.Length) { throw 'Existing binary preference has an unexpected length or type.' }
        [byte[]]$result = $Current.Clone()
        for ($i = 0; $i -lt $mask.Length; $i++) {
            $result[$i] = ($Current[$i] -band (255 -bxor $mask[$i])) -bor ($desired[$i] -band $mask[$i])
        }
        return ,$result
    }
    if ($Entry.Type -ceq 'String') {
        [uint32]$mask = 0
        [uint32]$desired = 0
        [uint32]$existing = 0
        if (-not [uint32]::TryParse([string]$Entry.Mask, [ref]$mask) -or
            -not [uint32]::TryParse([string]$Entry.Data, [ref]$desired)) { throw 'String Mask and Data must be unsigned decimal flags.' }
        if ($null -eq $Current) { return [string]$desired }
        if ($Current -isnot [string] -or -not [uint32]::TryParse($Current, [ref]$existing)) { throw 'Existing preference is not unsigned decimal flags.' }
        return [string](($existing -band ([uint32]::MaxValue -bxor $mask)) -bor ($desired -band $mask))
    }
    throw 'Mask supports only Binary or decimal String values.'
}

# Atlas.Registry domain: declarative registry entry application (tweak Registry arrays).

function Test-AtlasArchMatch {
    <#
    .SYNOPSIS
        Returns whether an entry's optional Arch gate ('X64' or 'ARM64') matches the
        current machine architecture. An absent gate always matches.
    #>
    param(
        [string]$Arch,

        [Parameter(Mandatory = $true)]
        [bool]$IsArm64
    )

    if ([string]::IsNullOrEmpty($Arch)) {
        return $true
    }

    switch ($Arch.ToUpperInvariant()) {
        'ARM64' { return $IsArm64 }
        'X64' { return -not $IsArm64 }
        default { throw "Unknown architecture gate '$Arch' (expected 'X64' or 'ARM64')." }
    }
}

function Get-AtlasRegistryEntryTargetScope {
    param(
        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [string]$Path
    )

    $pathInfo = ConvertTo-AtlasRegistryPathInfo -Path $Path
    if ($pathInfo.Root -eq 'HKEY_CURRENT_USER') {
        if (Test-AtlasProtectedCurrentUserPolicyPath -SubPath $pathInfo.SubPath) {
            return 'ProtectedCurrentUser'
        }
        return 'CurrentUser'
    }
    if ($pathInfo.Root -eq 'HKEY_USERS') {
        $hiveName = @($pathInfo.SubPath -split '\\', 2)[0]
        if ($hiveName -ceq $script:AtlasDefaultUserHiveName) {
            return 'DefaultUser'
        }
        return 'ExplicitUserHive'
    }
    return 'Machine'
}

function Get-AtlasRegistryEntryDescription {
    <#
    .SYNOPSIS
        Describes one declarative entry for a log or error message, so a failure names
        the exact value it could not apply.
    #>
    param(
        [Parameter(Mandatory = $true)]
        [hashtable]$Entry
    )

    $operation = if ($Entry.ContainsKey('Operation') -and $Entry['Operation']) { [string]$Entry['Operation'] } else { 'Set' }
    $path = if ($Entry.ContainsKey('Path') -and $Entry['Path']) { [string]$Entry['Path'] } else { '<no path>' }
    $name = if ($Entry.ContainsKey('Name')) { [string]$Entry['Name'] } else { '' }

    if ($operation -cin @('AddKey', 'DeleteKey')) {
        return "registry $operation of key '$path'"
    }
    if ([string]::IsNullOrEmpty($name)) {
        return "registry $operation of the default value at '$path'"
    }
    return "registry $operation of '$path\$name'"
}

function Invoke-AtlasRegistryEntries {
    <#
    .SYNOPSIS
        Applies a tweak's Registry entry array. Each entry is a hashtable with Path,
        Operation ('Set' default, 'Delete', 'DeleteKey', 'AddKey'), Name/Type/Data for
        value operations, and optional Arch and IgnoreErrors gates. Missing Delete and
        DeleteKey targets are successful no-ops. Other failures are fatal unless the
        entry explicitly declares IgnoreErrors, in which case they are logged.
        Scope permits install orchestration to separate machine entries, current-token
        HKCU entries, and fixed default-user entries into distinct trust contexts.
    #>
    param(
        [Parameter(Mandatory = $true)]
        [AllowEmptyCollection()]
        [hashtable[]]$Entries,

        [ValidateSet('All', 'Machine', 'ProtectedCurrentUser', 'CurrentUser', 'DefaultUser')]
        [string]$Scope = 'All',

        [bool]$IsArm64
    )

    $arm64 = if ($PSBoundParameters.ContainsKey('IsArm64')) {
        $IsArm64
    }
    else {
        [bool](Get-AtlasContext).IsArm64
    }

    foreach ($entry in $Entries) {
        $ignoreErrors = ($entry.ContainsKey('IgnoreErrors') -and $entry['IgnoreErrors'])
        $allowOsProtected = ($entry.ContainsKey('AllowOsProtected') -and $entry['AllowOsProtected'])
        $description = Get-AtlasRegistryEntryDescription -Entry $entry

        try {
            if (-not $entry.ContainsKey('Path') -or
                [string]::IsNullOrWhiteSpace([string]$entry['Path'])) {
                throw 'Registry entry has no Path.'
            }

            $targetScope = Get-AtlasRegistryEntryTargetScope -Path ([string]$entry['Path'])
            if ($targetScope -ceq 'ExplicitUserHive') {
                throw "Registry entry path '$($entry['Path'])' targets an explicit user hive; only ambient current-token HKCU or the fixed Atlas default-user hive is supported."
            }

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

            $operation = 'Set'
            if ($entry.ContainsKey('Operation') -and $entry['Operation']) {
                $operation = [string]$entry['Operation']
            }

            if ($entry.ContainsKey('Mask')) { $null = Merge-AtlasRegistryMaskedData -Entry $entry -Current $null }

            if ($entry.ContainsKey('UseGroupPolicy') -and $entry['UseGroupPolicy'] -isnot [bool]) {
                throw 'UseGroupPolicy must be a boolean.'
            }
            if ($entry.ContainsKey('UseGroupPolicy') -and $entry['UseGroupPolicy']) {
                if ($operation -cne 'Set' -or $entry['Type'] -ine 'DWord') {
                    throw 'UseGroupPolicy supports only Set operations with DWord data.'
                }
                Set-AtlasMachineDwordPolicy -Path $entry['Path'] -Name $entry['Name'] -Data $entry['Data']
                continue
            }

            switch ($operation) {
                'Set' {
                    $data = $entry['Data']
                    if ($entry.ContainsKey('Mask')) {
                        $current = Get-AtlasRegistryValueState -Path $entry.Path -Name $entry.Name
                        $currentData = $null
                        if ($current.ValueExists) {
                            $currentData = $current.Data
                            if ($current.Kind -cne $entry.Type) {
                                if ($entry.Type -ceq 'String' -and $current.Kind -ceq 'DWord' -and
                                    $entry.ContainsKey('MigrateDwordToString') -and $entry.MigrateDwordToString -eq $true) {
                                    # Legacy Atlas used DWORD for selected decimal flag strings.
                                    # Keep all 32 bits, including values returned as signed Int32.
                                    $flags = [BitConverter]::ToUInt32([BitConverter]::GetBytes([int]$currentData), 0)
                                    $currentData = $flags.ToString([Globalization.CultureInfo]::InvariantCulture)
                                }
                                else { throw 'Masked preference has an unexpected registry kind.' }
                            }
                        }
                        $data = Merge-AtlasRegistryMaskedData -Entry $entry -Current $currentData
                    }
                    Set-AtlasRegistryValue -Path $entry['Path'] -Name $entry['Name'] -Type $entry['Type'] `
                        -Data $data -AllowOsProtected:$allowOsProtected
                }
                'Delete' {
                    Remove-AtlasRegistryValue -Path $entry['Path'] -Name $entry['Name'] `
                        -AllowOsProtected:$allowOsProtected
                }
                'DeleteKey' {
                    Remove-AtlasRegistryKey -Path $entry['Path']
                }
                'AddKey' {
                    New-AtlasRegistryKey -Path $entry['Path']
                }
                default {
                    throw "Unknown registry operation '$operation'."
                }
            }
        }
        catch {
            if ($ignoreErrors) {
                Write-AtlasLog -Message "Ignoring failure of $description : $($_.Exception.Message)" `
                    -Level Warning -ErrorRecord $_
                continue
            }

            # A failure names the entry it came from; the raw exception says only what
            # the registry API reported, which is not enough to find the declaration.
            throw (New-Object System.Management.Automation.ErrorRecord(
                    (New-Object System.InvalidOperationException(
                        "Failed to apply $description : $($_.Exception.Message)",
                        $_.Exception)),
                    'AtlasRegistryEntryFailed',
                    [System.Management.Automation.ErrorCategory]::WriteError,
                    $description))
        }
    }
}

function Set-AtlasMachineDwordPolicy {
    param(
        [Parameter(Mandatory = $true)][string]$Path,
        [Parameter(Mandatory = $true)][string]$Name,
        [Parameter(Mandatory = $true)][int]$Data
    )

    $pathInfo = ConvertTo-AtlasRegistryPathInfo -Path $Path
    if ($pathInfo.Root -cne 'HKEY_LOCAL_MACHINE' -or $pathInfo.SubPath -notlike 'Software\Policies\*') {
        throw 'Group Policy entries require an HKLM Software\Policies path.'
    }
    if (-not (Test-AtlasAdmin)) { throw 'Administrator privileges are required to set machine policy.' }
    Set-AtlasMachineDwordPolicyNative -SubKey $pathInfo.SubPath -Name $Name -Data $Data
    Invoke-AtlasHiddenProcess -FilePath (Join-Path ([Environment]::SystemDirectory) 'gpupdate.exe') `
        -ArgumentList @('/target:computer', '/force', '/wait:600') -Wait -TimeoutSeconds 630 | Out-Null
    $drift = @(Test-AtlasRegistryEntries -Entries @(@{ Path = $Path; Name = $Name; Type = 'DWord'; Data = $Data }) -Scope Machine)
    if ($drift.Count -gt 0) { throw "Group Policy did not apply '$Path\$Name': $($drift[0].Reason)." }
    Write-AtlasLog -Message "Applied and verified local machine policy '$Path\$Name'."
}

function Set-AtlasMachineDwordPolicyNative {
    param([string]$SubKey, [string]$Name, [int]$Data)
    Initialize-AtlasNativeType
    [Atlas.Native.LocalMachinePolicy]::SetDword($SubKey, $Name, $Data)
}
