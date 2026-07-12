[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)]
    [ValidateSet('Disable', 'Minimal', 'Full')]
    [string]$State,

    [ValidateSet(0, 1)]
    [int]$RespectPowerModes = 0
)

Set-StrictMode -Version 3.0
$ErrorActionPreference = 'Stop'

if (@('Disable', 'Minimal', 'Full') -cnotcontains $State) {
    throw "Indexing machine state must use exact value 'Disable', 'Minimal', or 'Full'."
}
if ($State -cne 'Full' -and $PSBoundParameters.ContainsKey('RespectPowerModes')) {
    throw "Indexing machine state '$State' does not accept RespectPowerModes."
}

$indexConfiguration = Join-Path $PSScriptRoot 'Set-IndexConfiguration.ps1'
if (-not [IO.File]::Exists($indexConfiguration)) {
    throw "The Indexing configuration helper is missing at '$indexConfiguration'."
}

function Invoke-AtlasIndexOperation {
    param(
        [Parameter(Mandatory = $true)]
        [string]$Operation,

        [string]$IndexPath,

        [Nullable[int]]$SettingValue
    )

    $parameters = @{
        Operation = $Operation
        InProcess = $true
    }
    if ($PSBoundParameters.ContainsKey('IndexPath')) {
        $parameters.IndexPath = $IndexPath
    }
    if ($PSBoundParameters.ContainsKey('SettingValue')) {
        $parameters.SettingValue = [int]$SettingValue
    }
    & $indexConfiguration @parameters
}

if ($State -ceq 'Disable') {
    Invoke-AtlasIndexOperation -Operation Stop
    return
}

$windowsDirectory = [Environment]::GetFolderPath(
    [Environment+SpecialFolder]::Windows
)
$programData = [Environment]::GetFolderPath(
    [Environment+SpecialFolder]::CommonApplicationData
)
if ([string]::IsNullOrWhiteSpace($windowsDirectory) -or
    [string]::IsNullOrWhiteSpace($programData)) {
    throw 'Required Windows folders could not be resolved.'
}

$windowsDirectory = [IO.Path]::GetFullPath($windowsDirectory)
$programsPath = [IO.Path]::Combine(
    [IO.Path]::GetFullPath($programData),
    'Microsoft',
    'Windows',
    'Start Menu',
    'Programs'
)
$usersPath = [IO.Path]::Combine(
    [IO.Path]::GetPathRoot($windowsDirectory),
    'Users'
)
$atlasDesktopPath = [IO.Path]::Combine($windowsDirectory, 'AtlasDesktop')

Invoke-AtlasIndexOperation -Operation Stop
Invoke-AtlasIndexOperation -Operation CleanPolicies
Invoke-AtlasIndexOperation -Operation Include -IndexPath $programsPath
Invoke-AtlasIndexOperation -Operation Include -IndexPath $atlasDesktopPath

if ($State -ceq 'Minimal') {
    Invoke-AtlasIndexOperation -Operation Exclude -IndexPath $usersPath
    $respectPowerModesValue = 1
}
else {
    Invoke-AtlasIndexOperation -Operation Include -IndexPath $usersPath
    foreach ($userDirectory in @(
            Get-ChildItem -LiteralPath $usersPath -Directory -ErrorAction Stop
        )) {
        foreach ($childName in @('AppData', 'MicrosoftEdgeBackups')) {
            $excludePath = Join-Path $userDirectory.FullName $childName
            if (Test-Path -LiteralPath $excludePath `
                    -PathType Container -ErrorAction Stop) {
                Invoke-AtlasIndexOperation -Operation Exclude -IndexPath $excludePath
            }
        }
    }
    $respectPowerModesValue = $RespectPowerModes
}

Invoke-AtlasIndexOperation -Operation Start
Invoke-AtlasIndexOperation -Operation ResetSetupCompleted
Invoke-AtlasIndexOperation -Operation SetRespectPowerModes `
    -SettingValue $respectPowerModesValue
