# Toggle: Windows lock screen (policy show / hide).
@{
    Name      = 'LockScreen'
    Elevation = 'Admin'
    States    = [ordered]@{
        Show = @{
            StateValue = 1
            Launcher   = '4. Interface Tweaks\Lock Screen\Show Lock Screen (default).cmd'
            Reboot     = 'None'
            Action     = {
                param($Toggle)

                $policyKey = 'HKLM:\SOFTWARE\Policies\Microsoft\Windows\Personalization'
                Remove-ItemProperty -LiteralPath $policyKey -Name 'NoLockScreen' -Force -ErrorAction SilentlyContinue
                Remove-ItemProperty -LiteralPath $policyKey -Name 'NoChangingLockScreen' -Force -ErrorAction SilentlyContinue

                if (-not $Toggle.Silent) {
                    Write-Host 'Lock screen restored.' -ForegroundColor Green
                }
            }
        }
        Hide = @{
            StateValue = 0
            Launcher   = '4. Interface Tweaks\Lock Screen\Hide Lock Screen.cmd'
            Reboot     = 'None'
            Action     = {
                param($Toggle)

                $policyKey = 'HKLM:\SOFTWARE\Policies\Microsoft\Windows\Personalization'
                if (-not (Test-Path -LiteralPath $policyKey)) { New-Item -Path $policyKey -Force | Out-Null }
                New-ItemProperty -LiteralPath $policyKey -Name 'NoLockScreen' -Value 1 -PropertyType DWord -Force | Out-Null
                New-ItemProperty -LiteralPath $policyKey -Name 'NoChangingLockScreen' -Value 1 -PropertyType DWord -Force | Out-Null

                if (-not $Toggle.Silent) {
                    Write-Host 'Lock screen hidden.' -ForegroundColor Green
                }
            }
        }
    }
}
