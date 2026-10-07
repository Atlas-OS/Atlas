<#
.SYNOPSIS
    Captures existing profiles and recognizable pre-state-store Atlas choices.
#>
param([switch]$LibraryOnly)

Set-StrictMode -Version 3.0
$ErrorActionPreference = 'Stop'

# Reads, never writes, the installing user's live hive from TrustedInstaller. The
# values only pick which choices to import, and that user is the administrator
# running the install.
function Read-AtlasLegacyRegistryValue {
    param([string]$Path, [string]$Name, [string]$UserSid)
    $pathText = ($Path.Replace(':', '') -replace '\\+', '\').TrimEnd('\')
    $parts = $pathText -split '\\', 2
    $root = switch ($parts[0]) {
        'HKLM' { [Microsoft.Win32.Registry]::LocalMachine }
        'HKCU' { [Microsoft.Win32.Registry]::Users }
        default { return $null }
    }
    $subkey = $parts[1]
    if ($parts[0] -ceq 'HKCU') {
        if (-not $userSid) { return $null }
        $subkey = $userSid + '\' + $subkey
    }
    $key = $root.OpenSubKey($subkey, $false)
    if ($null -eq $key) { return @{ KeyExists = $false; Exists = $false; Value = $null } }
    try {
        $exists = @($key.GetValueNames()) -contains $Name
        return @{ KeyExists = $true; Exists = $exists; Kind = if ($exists) { [string]$key.GetValueKind($Name) } else { $null }; Value = $key.GetValue($Name, $null, [Microsoft.Win32.RegistryValueOptions]::DoNotExpandEnvironmentNames) }
    }
    finally { $key.Dispose() }
}

function Import-AtlasLegacyChoices {
    param([Parameter(Mandatory = $true)]$Context)

    Initialize-AtlasToggleStateStore
    $records = Get-AtlasToggleStateRecords
    $userSid = [string]$Context.InteractiveUserSid

    foreach ($file in Get-ChildItem (Join-Path $Context.AtlasModulesPath 'Toggles') -Filter '*.psd1' -Recurse) {
        $definition = Get-AtlasToggleDefinition -Name $file.BaseName
        # Older releases recorded some settings in launchers and others only in
        # .reg files. A partial store must not suppress capture of missing choices.
        if ($records.ContainsKey($definition.Name)) { continue }
        if ($definition.Contains('NoStateRecord') -and $definition.NoStateRecord) { continue }
        $matchingStates = @()
        foreach ($state in $definition.States.Values) {
            if (-not $state.Contains('StateValue') -or -not $state.Contains('Registry')) { continue }
            if ($state.Contains('NoStateRecord') -and $state.NoStateRecord) { continue }
            $match = $true
            $positiveEvidence = $false
            foreach ($entry in @($state.Registry)) {
                if ($entry.Contains('SkipVerification') -and $entry.SkipVerification) { continue }
                if (-not (Test-AtlasArchMatch -Arch ([string]$entry['Arch']) -IsArm64 ([bool]$Context.IsArm64))) { continue }
                $actual = Read-AtlasLegacyRegistryValue -Path ([string]$entry['Path']) -Name ([string]$entry['Name']) -UserSid $userSid
                if ($null -eq $actual) { $match = $false; break }
                $operation = [string]$entry['Operation']
                if ($operation -ceq 'DeleteKey') { if ($actual.KeyExists) { $match = $false }; continue }
                if ($operation -ceq 'Delete') { if ($actual.Exists) { $match = $false }; continue }
                if (-not $actual.Exists) { $match = $false; break }
                if ($actual.ContainsKey('Kind') -and $entry.Contains('Type') -and [string]$actual.Kind -ine [string]$entry.Type) {
                    $match = $false; break
                }
                $positiveEvidence = $true
                if ($entry.Contains('Mask')) {
                    $bytes = [byte[]]$actual.Value
                    $expected = [byte[]]$entry['Data']
                    $mask = [byte[]]$entry['Mask']
                    if ($bytes.Length -ne $expected.Length -or $mask.Length -ne $bytes.Length) { $match = $false; break }
                    for ($i = 0; $i -lt $bytes.Length; $i++) {
                        if (($bytes[$i] -band $mask[$i]) -ne ($expected[$i] -band $mask[$i])) { $match = $false; break }
                    }
                }
                elseif (($actual.Value -join '|') -cne ($entry['Data'] -join '|')) { $match = $false; break }
            }
            if ($match -and $positiveEvidence) { $matchingStates += $state }
        }
        if ($matchingStates.Count -eq 1) {
            Set-AtlasToggleState -Name $definition.Name -State ([int]$matchingStates[0].StateValue)
            Write-AtlasLog -Message "Adopted observed legacy choice '$($definition.Name)' state '$($matchingStates[0].Name)'."
        }
    }
    # These old launchers have imperative or changed declarations. Read their stable
    # distinguishing values rather than treating a missing record as the default.
    $recent = Read-AtlasLegacyRegistryValue -Path 'HKCU\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\Advanced' -Name 'Start_TrackDocs' -UserSid $userSid
    $recentPolicy = Read-AtlasLegacyRegistryValue -Path 'HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\Explorer' -Name 'NoRecentDocsHistory' -UserSid $userSid
    if (-not $records.ContainsKey('RecentItems') -and $null -ne $recent -and $recent.Exists -and $recent.Value -is [int] -and $recent.Value -eq 1 -and $null -ne $recentPolicy -and -not $recentPolicy.Exists) {
        Set-AtlasToggleState -Name RecentItems -State 1
    }
    if (-not $records.ContainsKey('Sleep')) {
        $scheme = Read-AtlasLegacyRegistryValue -Path 'HKLM\SYSTEM\CurrentControlSet\Control\Power\User\PowerSchemes' -Name ActivePowerScheme
        if ($null -ne $scheme -and $scheme.Exists -and [string]$scheme.Value -match '^[0-9a-f]{8}-([0-9a-f]{4}-){3}[0-9a-f]{12}$') {
            $sleepPath = 'HKLM\SYSTEM\CurrentControlSet\Control\Power\User\PowerSchemes\' + $scheme.Value + '\238c9fa8-0aad-41ed-83f4-97be242c8f20\abfc2519-3608-4c2a-94ea-171b0ed546ab'
            $sleep = Read-AtlasLegacyRegistryValue -Path $sleepPath -Name ACSettingIndex -UserSid $userSid
            if ($null -ne $sleep -and $sleep.Exists -and $sleep.Value -is [int] -and $sleep.Value -in @(0, 1)) {
                Set-AtlasToggleState -Name Sleep -State ([int]$sleep.Value)
            }
        }
    }
    Write-AtlasLog -Message 'Legacy choice capture completed; ambiguous or unobservable choices were not invented.'
}

if ($LibraryOnly) { return }
Assert-AtlasPrivilege -TrustedInstaller
$context = Get-AtlasContext -Refresh
if (-not $context.IsUpgrade) { return }
Import-Module (Join-Path (Split-Path -Parent (Split-Path -Parent $PSScriptRoot)) 'Modules\Atlas.Toggles\Atlas.Toggles.psd1') -ErrorAction Stop

$eligiblePath = 'HKLM:\SOFTWARE\AtlasOS\UpgradeUsers'
$null = New-Item -Path $eligiblePath -Force
foreach ($legacyProfile in Get-ChildItem 'HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\ProfileList') {
    if ($legacyProfile.PSChildName -match '^S-1-(5-21|12-1)-\d+-\d+-\d+-\d+$') {
        New-ItemProperty -LiteralPath $eligiblePath -Name $legacyProfile.PSChildName -Value ([string]$context.TargetVersion) -PropertyType String -Force | Out-Null
    }
}
Import-AtlasLegacyChoices -Context $context
