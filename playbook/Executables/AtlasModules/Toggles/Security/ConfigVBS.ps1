# Toggle: Show the current Core Isolation (VBS) configuration (info only, no state recorded).
# Converted from 'AtlasDesktop\7. Security\Core Isolation (VBS)\Current Configuration.cmd', which
# thinly launched 'ScriptWrappers\Set-VbsConfiguration.ps1' (a passthrough to 'Internal\Set-VbsConfiguration.ps1').
@{
    Name          = 'ConfigVBS'
    Elevation     = 'None'
    NoStateRecord = $true
    States        = [ordered]@{
        Run = @{
            Launcher        = '7. Security\Core Isolation (VBS)\Current Configuration.cmd'
            ToolboxLauncher = 'Scripts\vbsCurrentConfig.cmd'
            Reboot          = 'None'
            Action   = {
                param($Toggle)

                $script = Join-Path -Path $Toggle.ScriptsPath -ChildPath 'Internal\Set-VbsConfiguration.ps1'
                if (-not (Test-Path -LiteralPath $script -PathType Leaf)) {
                    Write-Host "Script not found: `"$script`"" -ForegroundColor Red
                    return
                }

                & $script
            }
        }
    }
}
