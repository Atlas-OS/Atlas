# Toggle: Fix installer errors 2502 and 2503 by resetting the Windows TEMP folder permissions
# (no state recording). Converted from 'AtlasDesktop\9. Troubleshooting\Fix Errors 2502 and 2503.cmd',
# which ran as TrustedInstaller (RunAsTI).
@{
    Name          = 'FixErrors2502and2503'
    Elevation     = 'TrustedInstaller'
    NoStateRecord = $true
    States        = [ordered]@{
        Run = @{
            Launcher        = '9. Troubleshooting\Fix Errors 2502 and 2503.cmd'
            ToolboxLauncher = 'Scripts\Troubleshooting\Fix Errors 2502 and 2503.cmd'
            Reboot          = 'None'
            Action   = {
                param($Toggle)

                $folder = "$($Toggle.WinDir)\Temp"

                if (-not $Toggle.Silent) {
                    Write-Host 'This script will fix errors 2502 and 2503 with Windows installers by resetting the Windows TEMP folder permissions.'
                    Write-Host 'This issue is not related to Atlas.'
                }

                Write-Host 'Taking ownership of TEMP folder as SYSTEM...'
                & "$($Toggle.WinDir)\System32\takeown.exe" /f $folder /r /d y | Out-Null

                Write-Host 'Clearing all current permissions...'
                $icacls = "$($Toggle.WinDir)\System32\icacls.exe"
                & $icacls $folder /inheritance:e | Out-Null
                & $icacls $folder /reset | Out-Null
                & $icacls $folder /inheritance:r | Out-Null

                Write-Host 'Setting default permissions...'
                & $icacls $folder /grant:r '*S-1-5-32-545:(OI)(CI)F' /grant:r '*S-1-5-18:(OI)(CI)F' /grant:r '*S-1-3-0:(OI)(CI)F' /grant:r '*S-1-5-11:(OI)(CI)(X,AD,WD)' /t | Out-Null

                Write-Host 'Clearing Windows temporary files...'
                # No error checking as some files and folders will be in use.
                Get-ChildItem -LiteralPath $folder -Recurse -File -Force -ErrorAction SilentlyContinue | Remove-Item -Force -ErrorAction SilentlyContinue

                Write-Host 'Completed.'
            }
        }
    }
}
