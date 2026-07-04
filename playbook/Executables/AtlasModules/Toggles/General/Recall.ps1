# Toggle: Recall / Windows AI data analysis (DisableAIDataAnalysis policy).
@{
    Name      = 'Recall'
    Elevation = 'Admin'
    States    = [ordered]@{
        Disable = @{
            StateValue = 0
            Launcher   = '3. General Configuration\AI Features\Recall\Disable Recall Support (default).cmd'
            Reboot     = 'None'
            Action     = {
                param($Toggle)

                $key = 'HKLM:\SOFTWARE\Policies\Microsoft\Windows\WindowsAI'
                if (-not (Test-Path -LiteralPath $key)) { New-Item -Path $key -Force | Out-Null }
                New-ItemProperty -LiteralPath $key -Name 'DisableAIDataAnalysis' -Value 1 -PropertyType DWord -Force | Out-Null
                # The policy is documented Device AND User scope - cover the user hive too.
                $userKey = 'HKCU:\SOFTWARE\Policies\Microsoft\Windows\WindowsAI'
                if (-not (Test-Path -LiteralPath $userKey)) { New-Item -Path $userKey -Force | Out-Null }
                New-ItemProperty -LiteralPath $userKey -Name 'DisableAIDataAnalysis' -Value 1 -PropertyType DWord -Force | Out-Null
                # 0 = Recall cannot be enabled: removes the Recall component bits and
                # deletes existing snapshots (24H2 26100.3915+; needs a restart to finish).
                New-ItemProperty -LiteralPath $key -Name 'AllowRecallEnablement' -Value 0 -PropertyType DWord -Force | Out-Null

                if (-not $Toggle.Silent) { Write-Host 'Recall has been disabled.' }
            }
        }
        Enable  = @{
            StateValue = 1
            Launcher   = '3. General Configuration\AI Features\Recall\Enable Recall Support.cmd'
            Reboot     = 'None'
            Action     = {
                param($Toggle)

                Remove-ItemProperty -LiteralPath 'HKLM:\SOFTWARE\Policies\Microsoft\Windows\WindowsAI' -Name 'DisableAIDataAnalysis' -Force -ErrorAction SilentlyContinue
                Remove-ItemProperty -LiteralPath 'HKCU:\SOFTWARE\Policies\Microsoft\Windows\WindowsAI' -Name 'DisableAIDataAnalysis' -Force -ErrorAction SilentlyContinue
                Remove-ItemProperty -LiteralPath 'HKLM:\SOFTWARE\Policies\Microsoft\Windows\WindowsAI' -Name 'AllowRecallEnablement' -Force -ErrorAction SilentlyContinue

                if (-not $Toggle.Silent) { Write-Host 'Recall has been enabled.' }
            }
        }
    }
}
