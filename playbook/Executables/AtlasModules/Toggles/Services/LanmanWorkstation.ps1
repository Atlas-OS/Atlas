# Toggle: Lanman Workstation / SMB services and the SmbDirect feature.
@{
    Name      = 'LanmanWorkstation'
    Elevation = 'Admin'
    Warning   = 'WARNING: This script will modify system services. Modifying services can lead to potential breakage of features and bugs. Proceed with caution, and refer to Atlas docs for more information!'
    States    = [ordered]@{
        Disable = @{
            StateValue  = 0
            ReplayScope = 'Machine'
            Launcher    = '6. Advanced Configuration\Services\Lanman Workstation (SMB)\Disable Lanman Workstation.cmd'
            Reboot      = 'Recommend'
            Action      = {
                param($Toggle)

                $setService = Join-Path $Toggle.ScriptsPath `
                    'Internal\Set-ServiceStartup.ps1'
                foreach ($entry in ([ordered]@{
                        KSecPkg = 4
                        LanmanServer = 4
                        LanmanWorkstation = 4
                        mrxsmb = 4
                        mrxsmb20 = 4
                        rdbss = 3
                        srv2 = 4
                    }).GetEnumerator()) {
                    & $setService -Name $entry.Key -Start $entry.Value
                }

                $feature = @(Dism\Get-WindowsOptionalFeature -Online -ErrorAction Stop |
                    Where-Object { $_.FeatureName -ceq 'SmbDirect' })
                if ($feature.Count -gt 1) {
                    throw 'More than one SmbDirect feature was returned.'
                }
                if ($feature.Count -eq 1) {
                    Dism\Disable-WindowsOptionalFeature -Online -FeatureName 'SmbDirect' `
                        -NoRestart -ErrorAction Stop | Out-Null
                    $feature = @(Dism\Get-WindowsOptionalFeature -Online `
                            -FeatureName 'SmbDirect' -ErrorAction Stop)
                    if ($feature.Count -ne 1 -or
                        [string]$feature[0].State -notin @(
                            'Disabled', 'DisablePending', 'DisabledWithPayloadRemoved'
                        )) {
                        throw 'SmbDirect did not reach a disabled state.'
                    }
                }
            }
        }
        Enable = @{
            StateValue  = 1
            ReplayScope = 'Machine'
            Launcher    = '6. Advanced Configuration\Services\Lanman Workstation (SMB)\Enable Lanman Workstation (default).cmd'
            Reboot      = 'Recommend'
            Action      = {
                param($Toggle)

                $setService = Join-Path $Toggle.ScriptsPath `
                    'Internal\Set-ServiceStartup.ps1'
                foreach ($entry in ([ordered]@{
                        KSecPkg = 0
                        LanmanServer = 2
                        LanmanWorkstation = 2
                        mrxsmb = 3
                        mrxsmb20 = 3
                        rdbss = 1
                        srv2 = 3
                    }).GetEnumerator()) {
                    & $setService -Name $entry.Key -Start $entry.Value
                }

                $feature = @(Dism\Get-WindowsOptionalFeature -Online -ErrorAction Stop |
                    Where-Object { $_.FeatureName -ceq 'SmbDirect' })
                if ($feature.Count -gt 1) {
                    throw 'More than one SmbDirect feature was returned.'
                }
                if ($feature.Count -eq 1) {
                    Dism\Enable-WindowsOptionalFeature -Online -FeatureName 'SmbDirect' `
                        -NoRestart -ErrorAction Stop | Out-Null
                    $feature = @(Dism\Get-WindowsOptionalFeature -Online `
                            -FeatureName 'SmbDirect' -ErrorAction Stop)
                    if ($feature.Count -ne 1 -or
                        [string]$feature[0].State -notin @('Enabled', 'EnablePending')) {
                        throw 'SmbDirect did not reach an enabled state.'
                    }
                }
            }
        }
    }
}
