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

function Invoke-AtlasRegistryEntries {
    <#
    .SYNOPSIS
        Applies a tweak's Registry entry array. Each entry is a hashtable with Path,
        Operation ('Set' default, 'Delete', 'DeleteKey', 'AddKey'), Name/Type/Data for
        value operations, and optional Arch and IgnoreErrors gates. Failures are logged
        as warnings (or swallowed with IgnoreErrors) so one bad entry never aborts a tweak.
    #>
    param(
        [Parameter(Mandatory = $true)]
        [AllowEmptyCollection()]
        [hashtable[]]$Entries
    )

    $context = Get-AtlasContext

    foreach ($entry in $Entries) {
        $ignoreErrors = ($entry.ContainsKey('IgnoreErrors') -and $entry['IgnoreErrors'])

        try {
            $arch = if ($entry.ContainsKey('Arch')) { [string]$entry['Arch'] } else { '' }
            if (-not (Test-AtlasArchMatch -Arch $arch -IsArm64 ([bool]$context.IsArm64))) {
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
            if ($ignoreErrors) {
                $null = $_
            }
            else {
                $entryPath = if ($entry.ContainsKey('Path')) { $entry['Path'] } else { '<no path>' }
                Write-AtlasLog -Message "Registry entry failed (path: '$entryPath'): $($_.Exception.Message)" -Level Warning
            }
        }
    }
}
