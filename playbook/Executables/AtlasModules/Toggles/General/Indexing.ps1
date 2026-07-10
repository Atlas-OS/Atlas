# Toggle: Windows Search Indexing (disabled / minimal / full).
#
# Runs as TrustedInstaller because the indexer policy keys and WSearch service
# reconfiguration require it.

# Invoke the PowerShell implementation in-process. This remains synchronous and
# creates no child console, while keeping dynamic index paths out of the shell's
# percent expansion and command-string parser.
function Invoke-AtlasIndexConfig {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [ValidateSet(
            'Include',
            'Exclude',
            'CleanPolicies',
            'Start',
            'Stop',
            'SetRespectPowerModes',
            'ResetSetupCompleted'
        )]
        [string]$Operation,

        [string]$IndexPath,

        [ValidateSet(0, 1)]
        [int]$SettingValue
    )

    $windowsDirectory = [Environment]::GetFolderPath([Environment+SpecialFolder]::Windows)
    if ([string]::IsNullOrWhiteSpace($windowsDirectory)) {
        throw 'The protected Windows directory could not be resolved.'
    }
    $helperPath = [IO.Path]::Combine(
        $windowsDirectory,
        'AtlasModules',
        'Scripts',
        'Internal',
        'Set-IndexConfiguration.ps1'
    )
    if (-not [IO.File]::Exists($helperPath)) {
        throw "The 'Set-IndexConfiguration.ps1' script wasn't found in AtlasModules."
    }

    $invokeParameters = @{
        InProcess = $true
        Operation = $Operation
    }
    if ($PSBoundParameters.ContainsKey('IndexPath')) {
        $invokeParameters.IndexPath = $IndexPath
    }
    if ($PSBoundParameters.ContainsKey('SettingValue')) {
        $invokeParameters.SettingValue = $SettingValue
    }

    & $helperPath @invokeParameters
}

@{
    Name      = 'Indexing'
    Elevation = 'TrustedInstaller'
    States    = [ordered]@{
        Disable = @{
            StateValue = 0
            Launcher   = '3. General Configuration\Search Indexing\Disable Search Indexing.cmd'
            Reboot     = 'None'
            Action     = {
                param($Toggle)

                Write-Host ''
                Write-Host 'Disabling search indexing...'
                Invoke-AtlasIndexConfig -Operation Stop

                if (-not $Toggle.Silent) {
                    Write-Host ''
                    Write-Host 'Search Indexing has been disabled.'
                }
            }
        }
        Minimal = @{
            StateValue = 1
            Launcher   = '3. General Configuration\Search Indexing\Minimal Search Indexing (default).cmd'
            Reboot     = 'None'
            Action     = {
                param($Toggle)

                if (-not $Toggle.Silent) {
                    Write-Host ''
                    Write-Host 'Configuring minimal search indexing...'
                }

                $programsPath = Join-Path `
                    -Path ([Environment]::GetFolderPath([Environment+SpecialFolder]::CommonApplicationData)) `
                    -ChildPath 'Microsoft\Windows\Start Menu\Programs'
                $usersPath = Join-Path `
                    -Path ([IO.Path]::GetPathRoot([Environment]::GetFolderPath([Environment+SpecialFolder]::Windows))) `
                    -ChildPath 'Users'

                Invoke-AtlasIndexConfig -Operation Stop
                Invoke-AtlasIndexConfig -Operation CleanPolicies
                Invoke-AtlasIndexConfig -Operation Include -IndexPath $programsPath
                Invoke-AtlasIndexConfig -Operation Include -IndexPath (Join-Path $Toggle.WinDir 'AtlasDesktop')
                Invoke-AtlasIndexConfig -Operation Exclude -IndexPath $usersPath

                Invoke-AtlasIndexConfig -Operation Start
                Invoke-AtlasIndexConfig -Operation ResetSetupCompleted

                # Pause indexing while on battery or in game mode to avoid performance loss.
                # Apply this after gpupdate so it is also the final verified state.
                Invoke-AtlasIndexConfig -Operation SetRespectPowerModes -SettingValue 1

                if (-not $Toggle.Silent) {
                    Write-Host ''
                    Write-Host 'Minimal Search Indexing has been configured.'
                }
            }
        }
        Enable  = @{
            StateValue = 2
            Launcher   = '3. General Configuration\Search Indexing\Enable Search Indexing.cmd'
            Reboot     = 'None'
            Action     = {
                param($Toggle)

                Write-Host ''
                Write-Host 'Enabling full search indexing...'
                $programsPath = Join-Path `
                    -Path ([Environment]::GetFolderPath([Environment+SpecialFolder]::CommonApplicationData)) `
                    -ChildPath 'Microsoft\Windows\Start Menu\Programs'
                $usersPath = Join-Path `
                    -Path ([IO.Path]::GetPathRoot([Environment]::GetFolderPath([Environment+SpecialFolder]::Windows))) `
                    -ChildPath 'Users'

                Invoke-AtlasIndexConfig -Operation Stop
                Invoke-AtlasIndexConfig -Operation CleanPolicies
                Invoke-AtlasIndexConfig -Operation Include -IndexPath $programsPath
                Invoke-AtlasIndexConfig -Operation Include -IndexPath (Join-Path $Toggle.WinDir 'AtlasDesktop')
                Invoke-AtlasIndexConfig -Operation Include -IndexPath $usersPath

                # Add default per-user exclusions
                foreach ($userDirectory in @(
                        Get-ChildItem -LiteralPath $usersPath -Directory -ErrorAction Stop
                    )) {
                    foreach ($childName in @('AppData', 'MicrosoftEdgeBackups')) {
                        $excludePath = Join-Path -Path $userDirectory.FullName -ChildPath $childName
                        if (Test-Path -LiteralPath $excludePath -PathType Container -ErrorAction Stop) {
                            Invoke-AtlasIndexConfig -Operation Exclude -IndexPath $excludePath
                        }
                    }
                }

                Invoke-AtlasIndexConfig -Operation Start
                Invoke-AtlasIndexConfig -Operation ResetSetupCompleted

                # Respect power settings while indexing to prevent performance loss during
                # gaming or battery drain (interactive choice, defaults to off in silent mode)
                $respectPowerModes = 0
                if (-not $Toggle.Silent) {
                    Write-Host ''
                    $answer = Read-Host 'Would you like to have indexing disable itself when on battery or gaming? [Y/N]'
                    if ($answer -match '^(y|yes)$') {
                        $respectPowerModes = 1
                    }
                }
                Invoke-AtlasIndexConfig `
                    -Operation SetRespectPowerModes `
                    -SettingValue $respectPowerModes

                if (-not $Toggle.Silent) {
                    Write-Host ''
                    Write-Host 'Full Search Indexing has been enabled.'
                }
            }
        }
    }
}
