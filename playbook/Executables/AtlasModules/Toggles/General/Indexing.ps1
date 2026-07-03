# Toggle: Windows Search Indexing (disabled / minimal / full).
# Converted from 'AtlasDesktop\3. General Configuration\Search Indexing\*.cmd'.
#
# Runs as TrustedInstaller like the original scripts (they relaunched via RunAsTI.cmd)
# because the indexer policy keys and WSearch service reconfiguration require it.
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

                $indexConf = Join-Path -Path $Toggle.ScriptsPath -ChildPath 'indexConf.cmd'
                if (-not (Test-Path -LiteralPath $indexConf -PathType Leaf)) {
                    Write-Host "The 'indexConf.cmd' script wasn't found in AtlasModules." -ForegroundColor Red
                    return
                }

                Write-Host ''
                Write-Host 'Disabling search indexing...'
                & "$env:ComSpec" /c "call `"$indexConf`" /stop"

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

                $indexConf = Join-Path -Path $Toggle.ScriptsPath -ChildPath 'indexConf.cmd'
                if (-not (Test-Path -LiteralPath $indexConf -PathType Leaf)) {
                    Write-Host "The 'indexConf.cmd' script wasn't found in AtlasModules." -ForegroundColor Red
                    return
                }

                if (-not $Toggle.Silent) {
                    Write-Host ''
                    Write-Host 'Configuring minimal search indexing...'
                }

                & "$env:ComSpec" /c "call `"$indexConf`" /stop"
                & "$env:ComSpec" /c "call `"$indexConf`" /cleanpolicies"
                & "$env:ComSpec" /c "call `"$indexConf`" /include `"$env:ProgramData\Microsoft\Windows\Start Menu\Programs`""
                & "$env:ComSpec" /c "call `"$indexConf`" /include `"$($Toggle.WinDir)\AtlasDesktop`""
                & "$env:ComSpec" /c "call `"$indexConf`" /exclude `"$env:SystemDrive\Users`""

                # Pause indexing while on battery or in game mode to avoid performance loss
                New-ItemProperty -LiteralPath 'HKLM:\SOFTWARE\Microsoft\Windows Search\Gather\Windows\SystemIndex' -Name 'RespectPowerModes' -Value 1 -PropertyType DWord -Force | Out-Null

                & "$env:ComSpec" /c "call `"$indexConf`" /start"
                New-ItemProperty -LiteralPath 'HKLM:\SOFTWARE\Microsoft\Windows Search' -Name 'SetupCompletedSuccessfully' -Value 0 -PropertyType DWord -Force | Out-Null

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

                $indexConf = Join-Path -Path $Toggle.ScriptsPath -ChildPath 'indexConf.cmd'
                if (-not (Test-Path -LiteralPath $indexConf -PathType Leaf)) {
                    Write-Host "The 'indexConf.cmd' script wasn't found in AtlasModules." -ForegroundColor Red
                    return
                }

                Write-Host ''
                Write-Host 'Enabling full search indexing...'
                & "$env:ComSpec" /c "call `"$indexConf`" /stop"
                & "$env:ComSpec" /c "call `"$indexConf`" /cleanpolicies"
                & "$env:ComSpec" /c "call `"$indexConf`" /include `"$env:ProgramData\Microsoft\Windows\Start Menu\Programs`""
                & "$env:ComSpec" /c "call `"$indexConf`" /include `"$($Toggle.WinDir)\AtlasDesktop`""
                & "$env:ComSpec" /c "call `"$indexConf`" /include `"$env:SystemDrive\Users`""

                # Add default per-user exclusions
                foreach ($userDirectory in @(Get-ChildItem -Path "$env:SystemDrive\Users" -Directory -ErrorAction SilentlyContinue)) {
                    foreach ($childName in @('AppData', 'MicrosoftEdgeBackups')) {
                        $excludePath = Join-Path -Path $userDirectory.FullName -ChildPath $childName
                        if (Test-Path -LiteralPath $excludePath) {
                            & "$env:ComSpec" /c "call `"$indexConf`" /exclude `"$excludePath`""
                        }
                    }
                }

                & "$env:ComSpec" /c "call `"$indexConf`" /start"
                New-ItemProperty -LiteralPath 'HKLM:\SOFTWARE\Microsoft\Windows Search' -Name 'SetupCompletedSuccessfully' -Value 0 -PropertyType DWord -Force | Out-Null

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
                New-ItemProperty -LiteralPath 'HKLM:\SOFTWARE\Microsoft\Windows Search\Gather\Windows\SystemIndex' -Name 'RespectPowerModes' -Value $respectPowerModes -PropertyType DWord -Force | Out-Null

                if (-not $Toggle.Silent) {
                    Write-Host ''
                    Write-Host 'Full Search Indexing has been enabled.'
                }
            }
        }
    }
}
