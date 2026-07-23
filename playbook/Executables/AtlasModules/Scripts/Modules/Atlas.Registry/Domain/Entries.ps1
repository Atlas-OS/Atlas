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

            switch ($operation) {
                'Set' {
                    Set-AtlasRegistryValue -Path $entry['Path'] -Name $entry['Name'] -Type $entry['Type'] -Data $entry['Data']
                }
                'Delete' {
                    Remove-AtlasRegistryValue -Path $entry['Path'] -Name $entry['Name']
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
            $entryPath = if ($entry.ContainsKey('Path')) { $entry['Path'] } else { '<no path>' }
            if ($ignoreErrors) {
                Write-AtlasLog -Message `
                    "Ignoring registry entry failure (path: '$entryPath'): $($_.Exception.Message)" `
                    -Level Warning -ErrorRecord $_
                continue
            }

            throw
        }
    }
}
