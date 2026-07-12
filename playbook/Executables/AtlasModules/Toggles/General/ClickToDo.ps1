# Toggle: Click To Do (Windows AI 'Click To Do' policy).
@{
    Name      = 'ClickToDo'
    Elevation = 'Admin'
    States    = [ordered]@{
        Disable = @{
            StateValue = 0
            Launcher   = '3. General Configuration\AI Features\Click To Do\Disable Click To Do (default).cmd'
            Reboot     = 'None'
            StateRecordScope = 'Machine'
            MachineAction = {
                param($Toggle)

                $key = 'HKLM:\SOFTWARE\Policies\Microsoft\Windows\WindowsAI'
                if (-not (Test-Path -LiteralPath $key)) { New-Item -Path $key -Force | Out-Null }
                New-ItemProperty -LiteralPath $key -Name 'DisableClickToDo' -Value 1 -PropertyType DWord -Force | Out-Null
            }
            UserAction = {
                param($Toggle)

                Import-Module -Name (Join-Path -Path $Toggle.ScriptsPath -ChildPath 'Modules\Atlas.Registry\Atlas.Registry.psd1') -Force -ErrorAction Stop
                Remove-AtlasRegistryValue -Path 'HKCU:\Software\Policies\Microsoft\Windows\WindowsAI' -Name 'DisableClickToDo'

                if (-not $Toggle.Silent) { Write-Host 'Click To Do has been disabled.' }
            }
        }
        Enable  = @{
            StateValue = 1
            Launcher   = '3. General Configuration\AI Features\Click To Do\Enable Click To Do.cmd'
            Reboot     = 'None'
            StateRecordScope = 'Machine'
            MachineAction = {
                param($Toggle)

                Import-Module -Name (Join-Path -Path $Toggle.ScriptsPath -ChildPath 'Modules\Atlas.Registry\Atlas.Registry.psd1') -Force -ErrorAction Stop
                Remove-AtlasRegistryValue -Path 'HKLM:\SOFTWARE\Policies\Microsoft\Windows\WindowsAI' -Name 'DisableClickToDo'
            }
            UserAction = {
                param($Toggle)

                Import-Module -Name (Join-Path -Path $Toggle.ScriptsPath -ChildPath 'Modules\Atlas.Registry\Atlas.Registry.psd1') -Force -ErrorAction Stop
                Remove-AtlasRegistryValue -Path 'HKCU:\Software\Policies\Microsoft\Windows\WindowsAI' -Name 'DisableClickToDo'

                if (-not $Toggle.Silent) { Write-Host 'Click To Do has been enabled.' }
            }
        }
    }
}
