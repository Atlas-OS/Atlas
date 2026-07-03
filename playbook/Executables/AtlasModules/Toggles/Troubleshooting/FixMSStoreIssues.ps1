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
                    Write-Host 'ERROR: StoreFixer.exe not found!' -ForegroundColor Red
                    return
                }

                if ($Toggle.Silent) {
                    & $storeFixer silent -wait
                } else {
                    Write-Host 'Running StoreFixer.exe...'
                    & $storeFixer -wait
                    Write-Host 'StoreFixer.exe completed.'
                }
            }
        }
    }
}
