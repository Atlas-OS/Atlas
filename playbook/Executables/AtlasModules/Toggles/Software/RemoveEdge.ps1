# Toggle: Install or Remove Microsoft Edge (plain action launcher, no state recording).
# Converted from 'AtlasDesktop\1. Software\Install or Remove Edge.cmd', which thinly launched
# 'ScriptWrappers\Remove-Edge.ps1' (a passthrough to 'Internal\Remove-Edge.ps1').
@{
    Name          = 'RemoveEdge'
    Elevation     = 'None'
    NoStateRecord = $true
    States        = [ordered]@{
        Run = @{
            Launcher = '1. Software\Install or Remove Edge.cmd'
            Reboot   = 'None'
            Action   = {
                param($Toggle)

                $script = Join-Path -Path $Toggle.ScriptsPath -ChildPath 'Internal\Remove-Edge.ps1'
                if (-not (Test-Path -LiteralPath $script -PathType Leaf)) {
                    Write-Host "Script not found: `"$script`"" -ForegroundColor Red
                    return
                }

                & $script
            }
        }
    }
}
