# Toggle: NVIDIA Display Container desktop context menu (enable/disable the service from the desktop).
@{
    Name      = 'NVidiaDisplayContainerContextMenu'
    Elevation = 'Admin'
    Warning   = 'WARNING: This script will modify system services. Modifying services can lead to potential breakage of features and bugs. Proceed with caution, and refer to Atlas docs for more information!'
    States    = [ordered]@{
        Add    = @{
            StateValue = 1
            Launcher   = '6. Advanced Configuration\Services\NVIDIA Display Container\Context Menu\Add Container Context Menu.cmd'
            Reboot     = 'RestartExplorer'
            Action     = {
                param($Toggle)

                if (-not (Test-Path -LiteralPath 'HKLM:\SYSTEM\CurrentControlSet\Services\NVDisplay.ContainerLocalSystem')) {
                    throw 'NVIDIA Display Container LS is not installed; its context menu cannot be added and no state was recorded.'
                }

                if (-not $Toggle.Silent) {
                    Write-Host 'Explorer will be restarted to ensure that the context menu works.'
                }

                $root = 'Registry::HKEY_CLASSES_ROOT\DesktopBackground\Shell\NVIDIAContainer'
                if (-not (Test-Path -LiteralPath $root)) { New-Item -Path $root -Force | Out-Null }
                New-ItemProperty -LiteralPath $root -Name 'Icon' -Value 'NVIDIA.ico,0' -PropertyType String -Force | Out-Null
                New-ItemProperty -LiteralPath $root -Name 'MUIVerb' -Value 'NVIDIA Container' -PropertyType String -Force | Out-Null
                New-ItemProperty -LiteralPath $root -Name 'Position' -Value 'Bottom' -PropertyType String -Force | Out-Null
                New-ItemProperty -LiteralPath $root -Name 'SubCommands' -Value '' -PropertyType String -Force | Out-Null

                $entry1 = 'Registry::HKEY_CLASSES_ROOT\DesktopBackground\shell\NVIDIAContainer\shell\NVIDIAContainer001'
                if (-not (Test-Path -LiteralPath $entry1)) { New-Item -Path $entry1 -Force | Out-Null }
                New-ItemProperty -LiteralPath $entry1 -Name 'HasLUAShield' -Value '' -PropertyType String -Force | Out-Null
                New-ItemProperty -LiteralPath $entry1 -Name 'MUIVerb' -Value 'Enable NVIDIA Display Container LS' -PropertyType String -Force | Out-Null
                $entry1Command = "$entry1\command"
                if (-not (Test-Path -LiteralPath $entry1Command)) { New-Item -Path $entry1Command -Force | Out-Null }
                New-ItemProperty -LiteralPath $entry1Command -Name '(default)' -Value "`"$($Toggle.WinDir)\AtlasDesktop\6. Advanced Configuration\Services\NVIDIA Display Container\Enable NVIDIA Display Container LS (default).cmd`"" -PropertyType String -Force | Out-Null

                $entry2 = 'Registry::HKEY_CLASSES_ROOT\DesktopBackground\shell\NVIDIAContainer\shell\NVIDIAContainer002'
                if (-not (Test-Path -LiteralPath $entry2)) { New-Item -Path $entry2 -Force | Out-Null }
                New-ItemProperty -LiteralPath $entry2 -Name 'HasLUAShield' -Value '' -PropertyType String -Force | Out-Null
                New-ItemProperty -LiteralPath $entry2 -Name 'MUIVerb' -Value 'Disable NVIDIA Display Container LS' -PropertyType String -Force | Out-Null
                $entry2Command = "$entry2\command"
                if (-not (Test-Path -LiteralPath $entry2Command)) { New-Item -Path $entry2Command -Force | Out-Null }
                New-ItemProperty -LiteralPath $entry2Command -Name '(default)' -Value "`"$($Toggle.WinDir)\AtlasDesktop\6. Advanced Configuration\Services\NVIDIA Display Container\Disable NVIDIA Display Container LS.cmd`"" -PropertyType String -Force | Out-Null
            }
        }
        Remove = @{
            StateValue = 0
            Launcher   = '6. Advanced Configuration\Services\NVIDIA Display Container\Context Menu\Remove Container Context Menu (default).cmd'
            Reboot     = 'RestartExplorer'
            Action     = {
                param($Toggle)

                if (-not (Test-Path -LiteralPath 'Registry::HKEY_CLASSES_ROOT\DesktopBackground\shell\NVIDIAContainer')) {
                    if (-not $Toggle.Silent) {
                        Write-Host 'The context menu does not exist, thus you cannot continue.'
                    }
                    return
                }

                if (-not $Toggle.Silent) {
                    Write-Host 'Explorer will be restarted to ensure that the context menu is removed.'
                }

                Remove-Item -LiteralPath 'Registry::HKEY_CLASSES_ROOT\DesktopBackground\Shell\NVIDIAContainer' `
                    -Recurse -Force -ErrorAction Stop
            }
        }
    }
}
