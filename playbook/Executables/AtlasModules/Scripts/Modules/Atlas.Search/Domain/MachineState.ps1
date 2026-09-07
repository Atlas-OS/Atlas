# Atlas.Search domain: the Disable, Minimal and Full indexing machine states shared
# by the install and the Indexing toggle.

function Set-AtlasIndexingMachineState {
    <#
    .SYNOPSIS
        Applies one indexing machine state. Disable stops WSearch and hides the
        settings page. Minimal and Full reset the policies, index the Start Menu and
        AtlasDesktop, then either exclude the Users folder (Minimal, RespectPowerModes
        forced to 1) or index it minus each profile's AppData and MicrosoftEdgeBackups
        (Full, with the requested -RespectPowerModes).
    #>
    param(
        [Parameter(Mandatory = $true)]
        [ValidateSet('Disable', 'Minimal', 'Full')]
        [string]$State,

        [ValidateSet(0, 1)]
        [int]$RespectPowerModes = 0,

        [switch]$PreservePowerModes
    )

    if (@('Disable', 'Minimal', 'Full') -cnotcontains $State) {
        throw "Indexing machine state must use exact value 'Disable', 'Minimal', or 'Full'."
    }
    if ($State -cne 'Full' -and $PSBoundParameters.ContainsKey('RespectPowerModes')) {
        throw "Indexing machine state '$State' does not accept RespectPowerModes."
    }
    if ($PreservePowerModes -and ($State -cne 'Full' -or $PSBoundParameters.ContainsKey('RespectPowerModes'))) {
        throw 'PreservePowerModes requires Full indexing without an explicit RespectPowerModes value.'
    }

    if ($State -ceq 'Disable') {
        Set-AtlasIndexConfiguration -Operation Stop
        Write-AtlasLog -Message 'Applied the Disable indexing machine state.'
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

    Set-AtlasIndexConfiguration -Operation Stop
    Set-AtlasIndexConfiguration -Operation CleanPolicies
    Set-AtlasIndexConfiguration -Operation Include -IndexPath $programsPath
    Set-AtlasIndexConfiguration -Operation Include -IndexPath $atlasDesktopPath

    if ($State -ceq 'Minimal') {
        Set-AtlasIndexConfiguration -Operation Exclude -IndexPath $usersPath
        $respectPowerModesValue = 1
    }
    else {
        Set-AtlasIndexConfiguration -Operation Include -IndexPath $usersPath
        foreach ($userDirectory in @(
                Get-ChildItem -LiteralPath $usersPath -Directory -ErrorAction Stop
            )) {
            foreach ($childName in @('AppData', 'MicrosoftEdgeBackups')) {
                $excludePath = Join-Path -Path $userDirectory.FullName -ChildPath $childName
                if (Test-Path -LiteralPath $excludePath `
                        -PathType Container -ErrorAction Stop) {
                    Set-AtlasIndexConfiguration -Operation Exclude -IndexPath $excludePath
                }
            }
        }
        $respectPowerModesValue = $RespectPowerModes
    }

    Set-AtlasIndexConfiguration -Operation Start
    if (-not $PreservePowerModes) {
        Set-AtlasIndexConfiguration -Operation SetRespectPowerModes `
            -SettingValue $respectPowerModesValue
    }
    Write-AtlasLog -Message "Applied the $State indexing machine state."
}
