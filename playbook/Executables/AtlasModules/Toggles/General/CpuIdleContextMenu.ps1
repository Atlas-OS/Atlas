# Toggle: CPU Idle desktop context menu (HKCR DesktopBackground shell entry).
#
# The 'Add' state writes the DesktopBackground\Shell\CpuIdle context-menu tree, whose Command
# values invoke the CPU Idle launchers (stored as REG_SZ, with %windir% intentionally left
# unexpanded).
@{
    Name      = 'CpuIdleContextMenu'
    Elevation = 'Admin'
    States    = [ordered]@{
        Add    = @{
            StateValue = 1
            ReplayScope = 'Machine'
            Launcher   = '3. General Configuration\CPU Idle\Desktop Context Menu\Add Idle Toggle in Desktop Context Menu.cmd'
            Reboot     = 'None'
            Action     = {
                param($Toggle)

                $root = 'Registry::HKEY_CLASSES_ROOT\DesktopBackground\Shell\CpuIdle'
                if (-not (Test-Path -LiteralPath $root)) { New-Item -Path $root -Force | Out-Null }
                New-ItemProperty -LiteralPath $root -Name 'Icon' -Value 'powercpl.dll' -PropertyType String -Force | Out-Null
                New-ItemProperty -LiteralPath $root -Name 'SubCommands' -Value '' -PropertyType String -Force | Out-Null
                New-ItemProperty -LiteralPath $root -Name 'Position' -Value 'Bottom' -PropertyType String -Force | Out-Null
                New-ItemProperty -LiteralPath $root -Name 'MUIVerb' -Value 'CPU Idle' -PropertyType String -Force | Out-Null

                $disable = "$root\Shell\Disable Idle"
                if (-not (Test-Path -LiteralPath $disable)) { New-Item -Path $disable -Force | Out-Null }
                New-ItemProperty -LiteralPath $disable -Name 'MUIVerb' -Value 'Disable Idle' -PropertyType String -Force | Out-Null
                New-ItemProperty -LiteralPath $disable -Name 'Icon' -Value 'powercpl.dll' -PropertyType String -Force | Out-Null

                $disableCmd = "$disable\Command"
                if (-not (Test-Path -LiteralPath $disableCmd)) { New-Item -Path $disableCmd -Force | Out-Null }
                New-ItemProperty -LiteralPath $disableCmd -Name '(default)' -Value 'cmd /c ""%windir%\AtlasDesktop\3. General Configuration\CPU Idle\Disable Idle.cmd"" /silent' -PropertyType String -Force | Out-Null
                New-ItemProperty -LiteralPath $disableCmd -Name 'Icon' -Value 'powercpl.dll' -PropertyType String -Force | Out-Null

                $enable = "$root\Shell\Enable Idle"
                if (-not (Test-Path -LiteralPath $enable)) { New-Item -Path $enable -Force | Out-Null }
                New-ItemProperty -LiteralPath $enable -Name 'MUIVerb' -Value 'Enable Idle' -PropertyType String -Force | Out-Null

                $enableCmd = "$enable\Command"
                if (-not (Test-Path -LiteralPath $enableCmd)) { New-Item -Path $enableCmd -Force | Out-Null }
                New-ItemProperty -LiteralPath $enableCmd -Name '(default)' -Value 'cmd /c ""%windir%\AtlasDesktop\3. General Configuration\CPU Idle\Enable Idle (default).cmd"" /silent' -PropertyType String -Force | Out-Null

                if (-not $Toggle.Silent) { Write-Host 'CPU Idle desktop context menu has been added.' }
            }
        }
        Remove = @{
            StateValue = 0
            ReplayScope = 'Machine'
            Launcher   = '3. General Configuration\CPU Idle\Desktop Context Menu\Remove Idle Toggle in Desktop Context Menu (default).cmd'
            Reboot     = 'None'
            Action     = {
                param($Toggle)

                Import-Module -Name (Join-Path $Toggle.ScriptsPath 'Modules\Atlas.Registry\Atlas.Registry.psd1') -ErrorAction Stop
                Remove-AtlasRegistryKey -Path 'Registry::HKEY_CLASSES_ROOT\DesktopBackground\Shell\CpuIdle'

                if (-not $Toggle.Silent) { Write-Host 'CPU Idle desktop context menu has been removed.' }
            }
        }
    }
}
