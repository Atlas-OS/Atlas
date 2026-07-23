# Toggle: Network item in the File Explorer navigation pane.
@{
    Name      = 'NetworkNavigationPane'
    Elevation = 'Admin'
    States    = [ordered]@{
        Disable = @{
            StateValue = 0
            Launcher   = '3. General Configuration\File Sharing\Network Navigation Pane\Disable Network Navigation Pane (default).cmd'
            Reboot     = 'None'
            StateRecordScope = 'Machine'
            MachineAction = { param($Toggle) }
            UserAction = {
                param($Toggle)

                Import-Module -Name (Join-Path $Toggle.ScriptsPath 'Modules\Atlas.Registry\Atlas.Registry.psd1') -ErrorAction Stop

                Set-AtlasRegistryValue -Path 'HKCU:\SOFTWARE\Classes\CLSID\{F02C1A0D-BE21-4350-88B0-7367FC96EF3C}' -Name 'System.IsPinnedToNameSpaceTree' -Type DWord -Data 0

                if (-not $Toggle.Silent) {
                    Write-Host 'Finished, Network Navigation Pane is now disabled.'
                }
            }
        }
        Enable  = @{
            StateValue = 1
            Launcher   = '3. General Configuration\File Sharing\Network Navigation Pane\User Network Navigation Pane choice.cmd'
            Reboot     = 'None'
            StateRecordScope = 'Machine'
            MachineAction = { param($Toggle) }
            UserAction = {
                param($Toggle)

                Import-Module -Name (Join-Path $Toggle.ScriptsPath 'Modules\Atlas.Registry\Atlas.Registry.psd1') -ErrorAction Stop

                Remove-AtlasRegistryValue -Path 'HKCU:\SOFTWARE\Classes\CLSID\{F02C1A0D-BE21-4350-88B0-7367FC96EF3C}' -Name 'System.IsPinnedToNameSpaceTree'

                if (-not $Toggle.Silent) {
                    Write-Host 'Finished, Network Navigation Pane is now enabled.'
                }
            }
        }
    }
}
