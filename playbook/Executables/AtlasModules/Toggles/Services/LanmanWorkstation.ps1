# Toggle: Lanman Workstation / SMB services and the SmbDirect feature.
#
# Services are set via the SetServiceStartup helper.
@{
    Name      = 'LanmanWorkstation'
    Elevation = 'Admin'
    Warning   = 'WARNING: This script will modify system services. Modifying services can lead to potential breakage of features and bugs. Proceed with caution, and refer to Atlas docs for more information!'
    States    = [ordered]@{
        Disable = @{
            StateValue = 0
            Launcher   = '6. Advanced Configuration\Services\Lanman Workstation (SMB)\Disable Lanman Workstation.cmd'
            Reboot     = 'Recommend'
            Action     = {
                param($Toggle)

                $setSvc = Join-Path -Path $Toggle.ScriptsPath -ChildPath 'Internal\Set-ServiceStartup.ps1'
                & $setSvc -Name 'KSecPkg' -Start 4
                & $setSvc -Name 'LanmanServer' -Start 4
                & $setSvc -Name 'LanmanWorkstation' -Start 4
                & $setSvc -Name 'mrxsmb' -Start 4
                & $setSvc -Name 'mrxsmb20' -Start 4
                & $setSvc -Name 'rdbss' -Start 3
                & $setSvc -Name 'srv2' -Start 4

                $dism = "$($Toggle.WinDir)\System32\dism.exe"
                & $dism /online /get-featureinfo /featurename:"SmbDirect" 2>$null | Out-Null
                if ($LASTEXITCODE -eq 0) {
                    & $dism /Online /Disable-Feature /FeatureName:"SmbDirect" /NoRestart | Out-Null
                }
            }
        }
        Enable  = @{
            StateValue = 1
            Launcher   = '6. Advanced Configuration\Services\Lanman Workstation (SMB)\Enable Lanman Workstation (default).cmd'
            Reboot     = 'Recommend'
            Action     = {
                param($Toggle)

                $setSvc = Join-Path -Path $Toggle.ScriptsPath -ChildPath 'Internal\Set-ServiceStartup.ps1'
                & $setSvc -Name 'KSecPkg' -Start 0
                & $setSvc -Name 'LanmanServer' -Start 2
                & $setSvc -Name 'LanmanWorkstation' -Start 2
                & $setSvc -Name 'mrxsmb' -Start 3
                & $setSvc -Name 'mrxsmb20' -Start 3
                & $setSvc -Name 'rdbss' -Start 1
                & $setSvc -Name 'srv2' -Start 3

                $dism = "$($Toggle.WinDir)\System32\dism.exe"
                & $dism /online /get-featureinfo /featurename:"SmbDirect" 2>$null | Out-Null
                if ($LASTEXITCODE -eq 0) {
                    & $dism /Online /Enable-Feature /FeatureName:"SmbDirect" /NoRestart | Out-Null
                }
            }
        }
    }
}
