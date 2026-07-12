# Toggle: Network Discovery services.
#
# Disable also unpins 'Network' from the Explorer sidebar (NetworkNavigationPane toggle);
# Enable first enables its Lanman Workstation (SMB) dependency. NlaSvc uses startup type 2
# on Windows 10 and 3 on Windows 11.
@{
    Name      = 'NetworkDiscovery'
    Elevation = 'Admin'
    Warning   = 'This script will modify system services.'
    States    = [ordered]@{
        Disable = @{
            StateValue = 0
            Launcher   = '6. Advanced Configuration\Services\Network Discovery\Disable Network Discovery Services.cmd'
            Reboot     = 'Recommend'
            StateRecordScope = 'Machine'
            MachineAction = {
                param($Toggle)

                $setSvc = Join-Path -Path $Toggle.ScriptsPath -ChildPath 'Internal\Set-ServiceStartup.ps1'
                foreach ($svc in @('fdPHost', 'FDResPub', 'lmhosts', 'SSDPSRV')) {
                    & $setSvc -Name $svc -Start 4
                }

                if (-not $Toggle.Silent) { Write-Host 'Finished, please reboot your device for changes to apply.' }
            }
            UserAction = {
                param($Toggle)

                Import-Module -Name (Join-Path $Toggle.ScriptsPath 'Modules\Atlas.Registry\Atlas.Registry.psd1') -Force -ErrorAction Stop
                Set-AtlasRegistryValue `
                    -Path 'HKCU:\SOFTWARE\Classes\CLSID\{F02C1A0D-BE21-4350-88B0-7367FC96EF3C}' `
                    -Name 'System.IsPinnedToNameSpaceTree' `
                    -Type DWord `
                    -Data 0
            }
        }
        Enable  = @{
            StateValue = 1
            Launcher   = '6. Advanced Configuration\Services\Network Discovery\Enable Network Discovery Services (default).cmd'
            Reboot     = 'Recommend'
            StateRecordScope = 'Machine'
            MachineAction = {
                param($Toggle)

                # Lanman Workstation (SMB) is a machine dependency. The closed service
                # reset plan already applies it immediately before NetworkDiscovery.
                if (-not $Toggle.ResetServices) {
                    Invoke-AtlasToggleMachineDependency `
                        -Name 'LanmanWorkstation' `
                        -State 'Enable' `
                        -StateRoot $Toggle.StateRoot
                }

                $setSvc = Join-Path -Path $Toggle.ScriptsPath -ChildPath 'Internal\Set-ServiceStartup.ps1'
                & $setSvc -Name 'eventlog' -Start 2
                foreach ($svc in @('fdPHost', 'FDResPub', 'lmhosts', 'netman')) {
                    & $setSvc -Name $svc -Start 3
                }
                if ($Toggle.WindowsBuild -lt 22000) {
                    & $setSvc -Name 'NlaSvc' -Start 2
                }
                else {
                    & $setSvc -Name 'NlaSvc' -Start 3
                }
                & $setSvc -Name 'SSDPSRV' -Start 3

                if (-not $Toggle.Silent) { Write-Host 'Finished, please reboot your device for changes to apply.' }
            }
            UserAction = { param($Toggle) }
        }
    }
}
