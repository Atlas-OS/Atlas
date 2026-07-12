# Toggle: Fix Microsoft Store issues by running StoreFixer.exe (no state recording).
@{
    Name          = 'FixMSStoreIssues'
    Elevation     = 'TrustedInstaller'
    NoStateRecord = $true
    States        = [ordered]@{
        Run = @{
            Launcher = '9. Troubleshooting\Fix MS Store Issues.cmd'
            Reboot   = 'None'
            Action   = {
                param($Toggle)

                $storeFixer = Join-Path -Path $Toggle.AtlasModulesPath -ChildPath 'Tools\StoreFixer.exe'
                if (-not (Test-Path -LiteralPath $storeFixer -PathType Leaf)) {
                    throw "Required StoreFixer executable is missing: '$storeFixer'."
                }

                if ($Toggle.Silent) {
                    Invoke-AtlasToggleNativeCommand -FilePath $storeFixer `
                        -ArgumentList ([string[]]@('silent', '-wait')) `
                        -AllowedExitCodes ([int[]]@(0)) | Out-Null
                } else {
                    Write-Host 'Running StoreFixer.exe...'
                    Invoke-AtlasToggleNativeCommand -FilePath $storeFixer `
                        -ArgumentList ([string[]]@('-wait')) `
                        -AllowedExitCodes ([int[]]@(0)) | Out-Null
                    Write-Host 'StoreFixer.exe completed.'
                }
            }
        }
    }
}
