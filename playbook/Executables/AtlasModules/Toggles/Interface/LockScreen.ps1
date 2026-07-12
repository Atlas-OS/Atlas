# Toggle: Windows lock screen (policy show / hide).
@{
    Name      = 'LockScreen'
    Elevation = 'Admin'
    States    = [ordered]@{
        Show = @{
            StateValue = 1
            Launcher   = '4. Interface Tweaks\Lock Screen\Show Lock Screen (default).cmd'
            Reboot     = 'None'
            ReplayScope = 'Machine'
            Action     = {
                param($Toggle)

                Import-Module -Name (Join-Path $Toggle.ScriptsPath 'Modules\Atlas.Registry\Atlas.Registry.psd1') -Force -ErrorAction Stop
                $policyKey = 'HKLM:\SOFTWARE\Policies\Microsoft\Windows\Personalization'
                Remove-AtlasRegistryValue -Path $policyKey -Name 'NoLockScreen'
                Remove-AtlasRegistryValue -Path $policyKey -Name 'NoChangingLockScreen'

                $verifyKey = [Microsoft.Win32.Registry]::LocalMachine.OpenSubKey(
                    'SOFTWARE\Policies\Microsoft\Windows\Personalization',
                    $false
                )
                if ($null -ne $verifyKey) {
                    try {
                        $remainingNames = @($verifyKey.GetValueNames())
                        foreach ($removedName in @('NoLockScreen', 'NoChangingLockScreen')) {
                            if ($remainingNames -contains $removedName) {
                                throw "Lock-screen policy value '$removedName' remains after removal."
                            }
                        }
                    }
                    finally {
                        $verifyKey.Dispose()
                    }
                }

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
