# Toggle: Network reset (Atlas adapter defaults vs. Windows defaults).
#
# AtlasDefault sets known latency-affecting NIC advanced properties to 0 on every PCI
# network adapter's driver class key. WindowsDefault runs the netsh reset stack and
# removes NIC devices so Windows redetects them with stock settings.
@{
    Name      = 'DefaultAtlasNetwork'
    Elevation = 'Admin'
    States    = [ordered]@{
        AtlasDefault   = @{
            StateValue = 1
            Launcher   = '9. Troubleshooting\Network\Reset Network to Atlas Default.cmd'
            Reboot     = 'Recommend'
            Action     = {
                param($Toggle)

                Write-Host 'Setting network settings to Atlas defaults...'

                $netKeys = @()
                foreach ($adapter in Get-CimInstance Win32_NetworkAdapter) {
                    if (-not $adapter.PNPDeviceID -or $adapter.PNPDeviceID -notmatch 'PCI\\VEN_') { continue }
                    $enumKey = "HKLM:\SYSTEM\CurrentControlSet\Enum\$($adapter.PNPDeviceID)"
                    $driver = (Get-ItemProperty -LiteralPath $enumKey -Name 'Driver' -ErrorAction SilentlyContinue).Driver
                    if ($driver) {
                        $netKeys += "HKLM:\SYSTEM\CurrentControlSet\Control\Class\$driver"
                    }
                }

                $settings = @('AutoDisableGigabit', 'ApCompatMode', 'SipsEnabled', 'ReduceSpeedOnPowerDown', 'DMACoalescing')
                foreach ($netKey in ($netKeys | Select-Object -Unique)) {
                    if (-not (Test-Path -LiteralPath $netKey)) { continue }
                    $existing = Get-ItemProperty -LiteralPath $netKey -ErrorAction SilentlyContinue
                    foreach ($setting in $settings) {
                        foreach ($name in @($setting, "*$setting")) {
                            if ($existing -and ($null -ne $existing.PSObject.Properties[$name])) {
                                Set-ItemProperty -LiteralPath $netKey -Name $name -Value '0' -Type String -Force
                            }
                        }
                    }
                }

                if (-not $Toggle.Silent) { Write-Host 'Finished, please reboot your device for changes to apply.' }
            }
        }
        WindowsDefault = @{
            StateValue = 0
            Launcher   = '9. Troubleshooting\Network\Reset Network to Windows Default.cmd'
            Reboot     = 'Recommend'
            Action     = {
                param($Toggle)

                Write-Host 'Resetting network settings to Windows defaults...'

                $netsh = "$($Toggle.WinDir)\System32\netsh.exe"
                & $netsh int ip reset | Out-Null
                & $netsh interface ipv4 reset | Out-Null
                & $netsh interface ipv6 reset | Out-Null
                & $netsh interface tcp reset | Out-Null
                & $netsh winsock reset | Out-Null

                $pnputil = "$($Toggle.WinDir)\System32\pnputil.exe"
                foreach ($dev in Get-PnpDevice -Class Net -Status 'OK' -ErrorAction SilentlyContinue) {
                    & $pnputil /remove-device $dev.InstanceId | Out-Null
                }
                & $pnputil /scan-devices | Out-Null

                if (-not $Toggle.Silent) { Write-Host 'Finished, please reboot your device for changes to apply.' }
            }
        }
    }
}
