# Toggle: Network Discovery services.
# Converted from 'AtlasDesktop\6. Advanced Configuration\Services\Network Discovery\*.cmd'.
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
            Action     = {
                param($Toggle)

                Invoke-AtlasToggle -Name 'NetworkNavigationPane' -State 'Disable' -Silent

                $setSvc = Join-Path -Path $Toggle.ScriptsPath -ChildPath 'Internal\SetServiceStartup.ps1'
                foreach ($svc in @('fdPHost', 'FDResPub', 'lmhosts', 'SSDPSRV')) {
                    & $setSvc -Name $svc -Start 4
                }

                if (-not $Toggle.Silent) { Write-Host 'Finished, please reboot your device for changes to apply.' }
            }
        }
        Enable  = @{
            StateValue = 1
            Launcher   = '6. Advanced Configuration\Services\Network Discovery\Enable Network Discovery Services (default).cmd'
            Reboot     = 'Recommend'
            Action     = {
                param($Toggle)

                # Lanman Workstation (SMB) is a dependency.
                Invoke-AtlasToggle -Name 'LanmanWorkstation' -State 'Enable' -Silent

                $setSvc = Join-Path -Path $Toggle.ScriptsPath -ChildPath 'Internal\SetServiceStartup.ps1'
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
        }
    }
}
