<#
.SYNOPSIS
    Dev/VM harness that dumps registry, service and scheduled-task state to JSON and
    compares two dumps, for triaging old-playbook vs new-playbook install differences.
.EXAMPLE
    .\Compare-SystemState.ps1 -Mode Dump -OutputPath baseline.json
    .\Compare-SystemState.ps1 -Mode Compare -Baseline baseline.json -Candidate candidate.json
#>
[CmdletBinding(DefaultParameterSetName = 'Dump')]
param(
    [Parameter(Mandatory = $true, ParameterSetName = 'Dump')]
    [ValidateNotNullOrEmpty()]
    [string]$OutputPath,

    [Parameter(ParameterSetName = 'Dump')]
    [string[]]$RegistryRoots = @(
        'HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion',
        'HKLM:\SYSTEM\CurrentControlSet\Services',
        'HKLM:\SOFTWARE\Policies',
        'HKCU:\Software\Microsoft\Windows\CurrentVersion'
    ),

    [Parameter(Mandatory = $true, ParameterSetName = 'Compare')]
    [ValidateNotNullOrEmpty()]
    [string]$Baseline,

    [Parameter(Mandatory = $true, ParameterSetName = 'Compare')]
    [ValidateNotNullOrEmpty()]
    [string]$Candidate,

    [Parameter(Mandatory = $true)]
    [ValidateSet('Dump', 'Compare')]
    [string]$Mode
)

Set-StrictMode -Version 3.0
$ErrorActionPreference = 'Stop'

function ConvertTo-StateString {
    param(
        [object]$Value,
        [Parameter(Mandatory = $true)][string]$Kind
    )

    if ($null -eq $Value) { return '' }

    switch ($Kind) {
        'Binary' { return (@($Value) | ForEach-Object { '{0:x2}' -f $_ }) -join '' }
        'MultiString' { return (@($Value) -join '|') }
        'None' { return '' }
        default { return [string]$Value }
    }
}

function Get-RegistrySnapshot {
    param([Parameter(Mandatory = $true)][string[]]$Roots)

    $values = @{}
    $keys = New-Object System.Collections.Generic.List[string]

    foreach ($root in $Roots) {
        if (-not (Test-Path -Path $root)) {
            Write-Warning "Registry root not found, skipping: $root"
            continue
        }

        $rootKeys = @(Get-Item -Path $root -ErrorAction SilentlyContinue) +
            @(Get-ChildItem -Path $root -Recurse -ErrorAction SilentlyContinue)

        foreach ($key in $rootKeys) {
            $keys.Add($key.Name)
            foreach ($valueName in $key.GetValueNames()) {
                $kind = 'Unknown'
                $data = ''
                try {
                    $kind = [string]$key.GetValueKind($valueName)
                    $raw = $key.GetValue($valueName, $null, [Microsoft.Win32.RegistryValueOptions]::DoNotExpandEnvironmentNames)
                    $data = ConvertTo-StateString -Value $raw -Kind $kind
                }
                catch {
                    $data = "<unreadable: $($_.Exception.Message)>"
                }

                $displayName = if ($valueName) { $valueName } else { '(default)' }
                $values["$($key.Name)::$displayName"] = "${kind}:${data}"
            }
        }
    }

    return [pscustomobject]@{
        Values = $values
        Keys   = @($keys | Sort-Object -Unique)
    }
}

function Get-ServiceStartSnapshot {
    $services = @{}
    foreach ($key in @(Get-ChildItem -Path 'HKLM:\SYSTEM\CurrentControlSet\Services' -ErrorAction SilentlyContinue)) {
        $start = $key.GetValue('Start', $null)
        if ($null -ne $start) {
            $services[$key.PSChildName] = [int]$start
        }
    }

    return $services
}

function Get-ScheduledTaskSnapshot {
    $tasks = @{}
    foreach ($task in @(Get-ScheduledTask -ErrorAction SilentlyContinue)) {
        $tasks["$($task.TaskPath)$($task.TaskName)"] = [string]$task.State
    }

    return $tasks
}

function ConvertTo-SortedDictionary {
    param([Parameter(Mandatory = $true)][hashtable]$Table)

    $sorted = [ordered]@{}
    foreach ($key in @($Table.Keys | Sort-Object)) {
        $sorted[$key] = $Table[$key]
    }

    return $sorted
}

function Read-StateSection {
    param(
        [Parameter(Mandatory = $true)][object]$State,
        [Parameter(Mandatory = $true)][string]$Section
    )

    $table = @{}
    $property = $State.PSObject.Properties[$Section]
    if ($null -ne $property -and $null -ne $property.Value) {
        foreach ($item in $property.Value.PSObject.Properties) {
            $table[$item.Name] = $item.Value
        }
    }

    return $table
}

function Compare-StateSection {
    param(
        [Parameter(Mandatory = $true)][string]$Label,
        [Parameter(Mandatory = $true)][hashtable]$BaselineTable,
        [Parameter(Mandatory = $true)][hashtable]$CandidateTable
    )

    $differences = 0
    foreach ($key in @($CandidateTable.Keys | Sort-Object)) {
        if (-not $BaselineTable.ContainsKey($key)) {
            Write-Host "[+] ${Label}: $key = $($CandidateTable[$key])" -ForegroundColor Green
            $differences++
        }
        elseif ("$($BaselineTable[$key])" -cne "$($CandidateTable[$key])") {
            Write-Host "[~] ${Label}: $key : $($BaselineTable[$key]) -> $($CandidateTable[$key])" -ForegroundColor Yellow
            $differences++
        }
    }

    foreach ($key in @($BaselineTable.Keys | Sort-Object)) {
        if (-not $CandidateTable.ContainsKey($key)) {
            Write-Host "[-] ${Label}: $key (was $($BaselineTable[$key]))" -ForegroundColor Red
            $differences++
        }
    }

    return $differences
}

if ($Mode -eq 'Dump') {
    Write-Host 'Collecting registry state...'
    $registry = Get-RegistrySnapshot -Roots $RegistryRoots
    Write-Host 'Collecting service Start values...'
    $services = Get-ServiceStartSnapshot
    Write-Host 'Collecting scheduled task states...'
    $tasks = Get-ScheduledTaskSnapshot

    $state = [ordered]@{
        Meta           = [ordered]@{
            Timestamp     = (Get-Date).ToString('o')
            ComputerName  = $env:COMPUTERNAME
            RegistryRoots = @($RegistryRoots)
        }
        RegistryValues = ConvertTo-SortedDictionary -Table $registry.Values
        RegistryKeys   = $registry.Keys
        Services       = ConvertTo-SortedDictionary -Table $services
        ScheduledTasks = ConvertTo-SortedDictionary -Table $tasks
    }

    $json = $state | ConvertTo-Json -Depth 5
    [System.IO.File]::WriteAllText(($PSCmdlet.GetUnresolvedProviderPathFromPSPath($OutputPath)), $json, [System.Text.Encoding]::UTF8)
    Write-Host "State dumped to '$OutputPath' ($($registry.Keys.Count) keys, $($registry.Values.Count) values, $($services.Count) services, $($tasks.Count) tasks)."
    exit 0
}

# Compare mode
foreach ($file in @($Baseline, $Candidate)) {
    if (-not (Test-Path -LiteralPath $file -PathType Leaf)) {
        throw "State file not found: '$file'."
    }
}

$baselineState = Get-Content -LiteralPath $Baseline -Raw | ConvertFrom-Json
$candidateState = Get-Content -LiteralPath $Candidate -Raw | ConvertFrom-Json

$totalDifferences = 0
$totalDifferences += Compare-StateSection -Label 'RegistryValue' `
    -BaselineTable (Read-StateSection -State $baselineState -Section 'RegistryValues') `
    -CandidateTable (Read-StateSection -State $candidateState -Section 'RegistryValues')
$totalDifferences += Compare-StateSection -Label 'Service' `
    -BaselineTable (Read-StateSection -State $baselineState -Section 'Services') `
    -CandidateTable (Read-StateSection -State $candidateState -Section 'Services')
$totalDifferences += Compare-StateSection -Label 'ScheduledTask' `
    -BaselineTable (Read-StateSection -State $baselineState -Section 'ScheduledTasks') `
    -CandidateTable (Read-StateSection -State $candidateState -Section 'ScheduledTasks')

# Key-only differences (keys with no values wouldn't show up in the value diff).
$baselineKeys = @{}
foreach ($key in @($baselineState.RegistryKeys)) { $baselineKeys[$key] = $true }
$candidateKeys = @{}
foreach ($key in @($candidateState.RegistryKeys)) { $candidateKeys[$key] = $true }
$totalDifferences += Compare-StateSection -Label 'RegistryKey' -BaselineTable $baselineKeys -CandidateTable $candidateKeys

if ($totalDifferences -eq 0) {
    Write-Host 'No differences found.' -ForegroundColor Green
    exit 0
}

Write-Host "$totalDifferences difference(s) found." -ForegroundColor Yellow
exit 1
