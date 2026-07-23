# Toggle: 'Run with priority' cascading entry in the .exe context menu.
@{
    Name      = 'RunWithPriority'
    Elevation = 'Admin'
    States    = [ordered]@{
        Add    = @{
            StateValue  = 1
            ReplayScope = 'Machine'
            Launcher    = '4. Interface Tweaks\Context Menus\Run With Priority\Add Run With Priority In Context Menu.cmd'
            Reboot      = 'None'
            Action      = {
                param($Toggle)

                Import-Module -Name (Join-Path $Toggle.ScriptsPath `
                        'Modules\Atlas.Registry\Atlas.Registry.psd1') `
                    -ErrorAction Stop

                $priorityRoot = 'HKLM:\SOFTWARE\Classes\exefile\Shell\Priority'
                $shellRoot = "$priorityRoot\ExtendedSubCommandsKey\Shell"
                $commandTemplate = '"%SystemRoot%\System32\WindowsPowerShell\v1.0\powershell.exe" -NoLogo -NoProfile -NonInteractive -WindowStyle Hidden -ExecutionPolicy Bypass -File "%SystemRoot%\AtlasModules\Scripts\Internal\Invoke-AtlasPriorityLaunch.ps1" -Priority "{0}" -TargetPath "%1"'
                $menuEntries = @(
                    @{ Key = '001flyout'; Label = 'Realtime'; Priority = 'Realtime' }
                    @{ Key = '002flyout'; Label = 'High'; Priority = 'High' }
                    @{ Key = '003flyout'; Label = 'Above normal'; Priority = 'AboveNormal' }
                    @{ Key = '004flyout'; Label = 'Normal'; Priority = 'Normal' }
                    @{ Key = '005flyout'; Label = 'Below normal'; Priority = 'BelowNormal' }
                    @{ Key = '006flyout'; Label = 'Low'; Priority = 'Low' }
                )

                Remove-AtlasRegistryKey -Path $priorityRoot
                Set-AtlasRegistryValue -Path $priorityRoot `
                    -Name 'MUIVerb' -Type String -Data 'Run with priority'
                Set-AtlasRegistryValue -Path $priorityRoot `
                    -Name 'MultiSelectModel' -Type String -Data 'Single'

                foreach ($entry in $menuEntries) {
                    $menuPath = "$shellRoot\$($entry.Key)"
                    Set-AtlasRegistryValue -Path $menuPath `
                        -Name 'MUIVerb' -Type String -Data $entry.Label
                    Set-AtlasRegistryValue -Path "$menuPath\command" `
                        -Name '' -Type ExpandString `
                        -Data ($commandTemplate -f $entry.Priority)
                }

                if (-not $Toggle.Silent) {
                    $Host.UI.WriteLine('Changes applied successfully.')
                }
            }
        }
        Remove = @{
            StateValue  = 0
            ReplayScope = 'Machine'
            Launcher    = '4. Interface Tweaks\Context Menus\Run With Priority\Remove Run With Priority In Context Menu (default).cmd'
            Reboot      = 'None'
            Action      = {
                param($Toggle)

                Import-Module -Name (Join-Path $Toggle.ScriptsPath `
                        'Modules\Atlas.Registry\Atlas.Registry.psd1') `
                    -ErrorAction Stop
                Remove-AtlasRegistryKey `
                    -Path 'HKLM:\SOFTWARE\Classes\exefile\Shell\Priority'

                if (-not $Toggle.Silent) {
                    $Host.UI.WriteLine('Changes applied successfully.')
                }
            }
        }
    }
}
