# Atlas.Services domain: declarative service entry application (tweak and toggle
# Services arrays).

function Invoke-AtlasServiceEntries {
    <#
    .SYNOPSIS
        Applies a Services entry array. Each entry is a hashtable with Name, an
        Operation of 'Change' (default), 'Stop' or 'Start', a StartupType of 0-4 for
        Change, an optional AllowMissing switch that tolerates an absent optional
        service or driver, and an optional IgnoreErrors switch that turns any failure
        into a logged warning.
    #>
    param(
        [Parameter(Mandatory = $true)]
        [AllowEmptyCollection()]
        [hashtable[]]$Entries
    )

    foreach ($entry in $Entries) {
        $ignoreErrors = $entry.ContainsKey('IgnoreErrors') -and [bool]$entry['IgnoreErrors']
        $entryName = if ($entry.ContainsKey('Name')) { [string]$entry['Name'] } else { '<no name>' }
        try {
            if (-not $entry.ContainsKey('Name') -or [string]::IsNullOrWhiteSpace([string]$entry['Name'])) {
                throw 'Service entry has no Name.'
            }
            $serviceName = [string]$entry['Name']

            $operation = 'Change'
            if ($entry.ContainsKey('Operation') -and $entry['Operation']) {
                $operation = [string]$entry['Operation']
            }
            switch ($operation) {
                'Change' {
                    # Set-AtlasServiceStartup writes the service key directly (Set-Service
                    # cannot touch protected/driver services) and verifies retention,
                    # because tamper-protected services silently discard Start writes.
                    $startupType = if ($entry.ContainsKey('StartupType')) { $entry['StartupType'] } else { $null }
                    if ($null -eq $startupType -or [int]$startupType -lt 0 -or [int]$startupType -gt 4) {
                        throw "Service entry has no valid StartupType (expected 0-4, got '$startupType')."
                    }
                    $allowMissing = $entry.ContainsKey('AllowMissing') -and [bool]$entry['AllowMissing']
                    Set-AtlasServiceStartup -Name $serviceName -StartupType ([int]$startupType) `
                        -AllowMissing:$allowMissing
                }
                'Stop' {
                    Stop-Service -Name $serviceName -Force -ErrorAction Stop
                }
                'Start' {
                    Start-Service -Name $serviceName -ErrorAction Stop
                }
                default {
                    throw "Unknown service operation '$operation'."
                }
            }
        }
        catch {
            if ($ignoreErrors) {
                Write-AtlasLog -Message "Ignored service entry failure (service: '$entryName'): $($_.Exception.Message)" -Level Warning
                continue
            }
            throw
        }
    }
}

function Test-AtlasServiceEntries {
    <#
    .SYNOPSIS
        Reports every Change entry whose service Start value differs from its
        StartupType. Stop and Start operations describe transient state and are not
        verified. A missing service drifts unless the entry declares AllowMissing.
    #>
    param(
        [Parameter(Mandatory = $true)]
        [AllowEmptyCollection()]
        [hashtable[]]$Entries,

        [ValidateNotNullOrEmpty()]
        [string]$ServicesRoot = 'HKLM:\SYSTEM\CurrentControlSet\Services'
    )

    $drift = @()
    foreach ($entry in $Entries) {
        $operation = if ($entry.ContainsKey('Operation') -and $entry['Operation']) { [string]$entry['Operation'] } else { 'Change' }
        if ($operation -cne 'Change' -or -not $entry.ContainsKey('Name')) {
            continue
        }
        $name = [string]$entry['Name']
        $expected = [int]$entry['StartupType']
        $servicePath = Join-Path -Path $ServicesRoot -ChildPath $name
        if (-not (Test-Path -LiteralPath $servicePath)) {
            if (-not ($entry.ContainsKey('AllowMissing') -and [bool]$entry['AllowMissing'])) {
                $drift += [pscustomobject]@{ Service = $name; Expected = $expected; Actual = $null; Reason = 'service is missing' }
            }
            continue
        }
        $actual = (Get-ItemProperty -LiteralPath $servicePath -Name 'Start' -ErrorAction SilentlyContinue).Start
        if ($null -eq $actual -or [int]$actual -ne $expected) {
            $drift += [pscustomobject]@{ Service = $name; Expected = $expected; Actual = $actual; Reason = 'startup type differs' }
        }
    }
    return $drift
}
