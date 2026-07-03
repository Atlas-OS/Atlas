# Toggle: File Sharing (network discovery, SMB, NetBIOS bindings).
# Converted from 'AtlasDesktop\3. General Configuration\File Sharing\*.cmd'.
#
# The original launchers were thin wrappers that ran the ScriptWrappers\*FileSharing.ps1
# scripts, which simply forward to the Internal\*FileSharing.ps1 scripts. This definition
# calls the Internal scripts directly (their real implementation), then the engine handles
# the "restart now?" prompt (Reboot = 'Prompt').
@{
    Name      = 'FileSharing'
    Elevation = 'Admin'
    States    = [ordered]@{
        Disable = @{
            StateValue = 0
            Launcher        = '3. General Configuration\File Sharing\Disable File Sharing (default).cmd'
            ToolboxLauncher = 'ConfigurationServices\FIleSharing\disable.cmd'
            Reboot          = 'Prompt'
            Action     = {
                param($Toggle)

                $script = Join-Path -Path $Toggle.ScriptsPath -ChildPath 'Internal\Disable-FileSharing.ps1'
                if (-not (Test-Path -LiteralPath $script -PathType Leaf)) {
                    Write-Host "Script not found: `"$script`"" -ForegroundColor Red
                    return
                }

                & $script -Silent:$Toggle.Silent

                if (-not $Toggle.Silent) {
                    Write-Host 'Finished, File Sharing is now disabled.'
                }
            }
        }
        Enable  = @{
            StateValue = 1
            Launcher        = '3. General Configuration\File Sharing\Enable File Sharing.cmd'
            ToolboxLauncher = 'ConfigurationServices\FIleSharing\enable.cmd'
            Reboot          = 'Prompt'
            Action     = {
                param($Toggle)

                $script = Join-Path -Path $Toggle.ScriptsPath -ChildPath 'Internal\Enable-FileSharing.ps1'
                if (-not (Test-Path -LiteralPath $script -PathType Leaf)) {
                    Write-Host "Script not found: `"$script`"" -ForegroundColor Red
                    return
                }

                & $script -Silent:$Toggle.Silent

                if (-not $Toggle.Silent) {
                    Write-Host 'Finished, File Sharing is now enabled.'
                }
            }
        }
    }
}
