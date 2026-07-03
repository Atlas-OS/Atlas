# Toggle: Microsoft Store (remove/reinstall the Store app package).
@{
    Name      = 'MicrosoftStore'
    Elevation = 'Admin'
    Warning   = 'WARNING: This script will modify system services. Modifying services can lead to potential breakage of features and bugs. Proceed with caution, and refer to Atlas docs for more information!'
    States    = [ordered]@{
        Disable = @{
            StateValue = 0
            Launcher   = '6. Advanced Configuration\Microsoft Store\Disable Microsoft Store.cmd'
            Reboot     = 'None'
            Action     = {
                param($Toggle)

                Get-AppxPackage -AllUsers Microsoft.WindowsStore | Remove-AppxPackage -ErrorAction SilentlyContinue

                if (-not $Toggle.Silent) {
                    Write-Host ''
                    Write-Host 'Microsoft Store has been removed.'
                    Write-Host 'You can restore it later with the enable script.'
                }
            }
        }
        Enable  = @{
            StateValue = 1
            Launcher   = '6. Advanced Configuration\Microsoft Store\Enable Microsoft Store (default).cmd'
            Reboot     = 'None'
            Action     = {
                param($Toggle)

                Get-AppxPackage -AllUsers Microsoft.WindowsStore | ForEach-Object {
                    Add-AppxPackage -DisableDevelopmentMode -Register (Join-Path $_.InstallLocation 'AppXManifest.xml') -ErrorAction SilentlyContinue
                }

                if (-not $Toggle.Silent) {
                    Write-Host ''
                    Write-Host 'Microsoft Store has been reinstalled/enabled.'
                }
            }
        }
    }
}
