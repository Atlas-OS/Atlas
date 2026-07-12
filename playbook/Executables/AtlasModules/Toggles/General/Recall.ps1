# Toggle: Recall / Windows AI data analysis (DisableAIDataAnalysis policy).
@{
    Name      = 'Recall'
    Elevation = 'Admin'
    States    = [ordered]@{
        Disable = @{
            StateValue = 0
            Launcher   = '3. General Configuration\AI Features\Recall\Disable Recall Support (default).cmd'
            Reboot     = 'None'
            StateRecordScope = 'Machine'
            MachineAction = {
                param($Toggle)

                $key = 'HKLM:\SOFTWARE\Policies\Microsoft\Windows\WindowsAI'
                if (-not (Test-Path -LiteralPath $key)) { New-Item -Path $key -Force | Out-Null }
                New-ItemProperty -LiteralPath $key -Name 'DisableAIDataAnalysis' -Value 1 -PropertyType DWord -Force | Out-Null
                # 0 = Recall cannot be enabled: removes the Recall component bits and
                # deletes existing snapshots (24H2 26100.3915+; needs a restart to finish).
                New-ItemProperty -LiteralPath $key -Name 'AllowRecallEnablement' -Value 0 -PropertyType DWord -Force | Out-Null
            }
            UserAction = {
                param($Toggle)

                # The policy is documented Device AND User scope - cover the initiating user hive too.
                $userKey = 'HKCU:\SOFTWARE\Policies\Microsoft\Windows\WindowsAI'
                if (-not (Test-Path -LiteralPath $userKey)) { New-Item -Path $userKey -Force | Out-Null }
                New-ItemProperty -LiteralPath $userKey -Name 'DisableAIDataAnalysis' -Value 1 -PropertyType DWord -Force | Out-Null

                if (-not $Toggle.Silent) { Write-Host 'Recall has been disabled.' }
            }
        }
        Enable  = @{
            StateValue = 1
            Launcher   = '3. General Configuration\AI Features\Recall\Enable Recall Support.cmd'
            Reboot     = 'None'
            StateRecordScope = 'Machine'
            MachineAction = {
                param($Toggle)

                Import-Module -Name (Join-Path $Toggle.ScriptsPath 'Modules\Atlas.Registry\Atlas.Registry.psd1') -Force -ErrorAction Stop
                Remove-AtlasRegistryValue -Path 'HKLM:\SOFTWARE\Policies\Microsoft\Windows\WindowsAI' -Name 'DisableAIDataAnalysis'
                Remove-AtlasRegistryValue -Path 'HKLM:\SOFTWARE\Policies\Microsoft\Windows\WindowsAI' -Name 'AllowRecallEnablement'
            }
            UserAction = {
                param($Toggle)

                Import-Module -Name (Join-Path $Toggle.ScriptsPath 'Modules\Atlas.Registry\Atlas.Registry.psd1') -Force -ErrorAction Stop
                Remove-AtlasRegistryValue -Path 'HKCU:\SOFTWARE\Policies\Microsoft\Windows\WindowsAI' -Name 'DisableAIDataAnalysis'

                if (-not $Toggle.Silent) { Write-Host 'Recall has been enabled.' }
            }
        }
    }
}
