# Toggle: Virtualization-Based Security (Core Isolation / memory integrity).
@{
    Name      = 'VbsState'
    Elevation = 'Admin'
    States    = [ordered]@{
        Disable = @{
            StateValue = 0
            Launcher   = '7. Security\Core Isolation (VBS)\Disable VBS.cmd'
            Reboot     = 'None'
            Action     = {
                param($Toggle)

                $hvci = 'HKLM:\SYSTEM\CurrentControlSet\Control\DeviceGuard\Scenarios\HypervisorEnforcedCodeIntegrity'
                if (-not (Test-Path -LiteralPath $hvci)) { New-Item -Path $hvci -Force | Out-Null }
                New-ItemProperty -LiteralPath $hvci -Name 'Enabled' -Value 0 -PropertyType DWord -Force | Out-Null

                $dg = 'HKLM:\SYSTEM\CurrentControlSet\Control\DeviceGuard'
                if (-not (Test-Path -LiteralPath $dg)) { New-Item -Path $dg -Force | Out-Null }
                New-ItemProperty -LiteralPath $dg -Name 'EnableVirtualizationBasedSecurity' -Value 0 -PropertyType DWord -Force | Out-Null

                if (-not $Toggle.Silent) { Write-Host 'Changes applied successfully.' }
            }
        }
        Enable  = @{
            StateValue = 1
            Launcher   = '7. Security\Core Isolation (VBS)\Enable VBS.cmd'
            Reboot     = 'None'
            Action     = {
                param($Toggle)

                $hvci = 'HKLM:\SYSTEM\CurrentControlSet\Control\DeviceGuard\Scenarios\HypervisorEnforcedCodeIntegrity'
                if (-not (Test-Path -LiteralPath $hvci)) { New-Item -Path $hvci -Force | Out-Null }
                New-ItemProperty -LiteralPath $hvci -Name 'Enabled' -Value 1 -PropertyType DWord -Force | Out-Null

                $dg = 'HKLM:\SYSTEM\CurrentControlSet\Control\DeviceGuard'
                if (-not (Test-Path -LiteralPath $dg)) { New-Item -Path $dg -Force | Out-Null }
                New-ItemProperty -LiteralPath $dg -Name 'EnableVirtualizationBasedSecurity' -Value 1 -PropertyType DWord -Force | Out-Null

                if (-not $Toggle.Silent) { Write-Host 'Changes applied successfully.' }
            }
        }
    }
}
