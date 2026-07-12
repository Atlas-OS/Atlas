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

                $packages = @(Get-AppxPackage -AllUsers Microsoft.WindowsStore -ErrorAction Stop)
                foreach ($package in $packages) {
                    $package | Remove-AppxPackage -AllUsers -ErrorAction Stop
                }

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

                $packages = @(Get-AppxPackage -AllUsers Microsoft.WindowsStore -ErrorAction Stop)
                if ($packages.Count -eq 0) {
                    throw 'Microsoft Store is not provisioned on this image, so it cannot be registered and no enabled state was recorded.'
                }
                foreach ($package in $packages) {
                    $manifestPath = Join-Path -Path $package.InstallLocation `
                        -ChildPath 'AppXManifest.xml'
                    if (-not (Test-Path -LiteralPath $manifestPath -PathType Leaf)) {
                        throw "Microsoft Store manifest is missing at '$manifestPath'."
                    }
                    Add-AppxPackage -DisableDevelopmentMode -Register $manifestPath `
                        -ErrorAction Stop
                }

                if (-not $Toggle.Silent) {
                    Write-Host ''
                    Write-Host 'Microsoft Store has been reinstalled/enabled.'
                }
            }
        }
    }
}
