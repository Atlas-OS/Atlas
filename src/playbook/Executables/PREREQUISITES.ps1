$env:PSModulePath += ";$PWD\AtlasModules\Scripts\Modules"

if ($env:AtlasUnsupportedInstall -eq 'True') {
    Write-Warning "Unsupported install!"
    exit 10
}

if ((Get-ItemProperty 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\OEMInformation' -Name 'Model' -EA 0).Model -notmatch 'Atlas') {
    if (20 -lt ((Get-Date) - (Get-CimInstance Win32_OperatingSystem).InstallDate).Days) {
        $title = 'Atlas - Unsupported Installation'
        $msg1 = @'
Windows seems to have been installed a while ago.

A full Windows reinstall following our guide is required to ensure your initial install of Atlas works without problems.

Would you like to go to the guide now, and halt the installation? https://docs.atlasos.net/
'@
        $msg2 = @'
Are you sure you want to proceed with an unsupported installation?

Please note that if you ever want to uninstall Atlas, you must reinstall Windows.
'@

        if (((Read-MessageBox -Title $title -Body $msg1 -Icon Warning) -eq 'Yes') -or ((Read-MessageBox -Title $title -Body $msg2 -Icon Stop) -eq 'No')) {
            Start-Process "https://docs.atlasos.net/getting-started/installation/"
            exit 11
        }

        $machine = [System.EnvironmentVariableTarget]::Machine
        [Environment]::SetEnvironmentVariable('AtlasUnsupportedInstall', 'True', $machine)
    }
}