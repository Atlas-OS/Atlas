# Toggle: Install Software (plain action launcher, no state recording).
# Converted from 'AtlasDesktop\1. Software\Install Software.cmd', which thinly launched
# 'ScriptWrappers\Install-Software.ps1' (a passthrough to 'Internal\Install-Software.ps1').
@{
    Name          = 'InstallSoftware'
    Elevation     = 'None'
    NoStateRecord = $true
    States        = [ordered]@{
        Run = @{
            Launcher = '1. Software\Install Software.cmd'
            Reboot   = 'None'
            Action   = {
                param($Toggle)

                $script = Join-Path -Path $Toggle.ScriptsPath -ChildPath 'Internal\Install-Software.ps1'
                if (-not (Test-Path -LiteralPath $script -PathType Leaf)) {
                    Write-Host "Script not found: `"$script`"" -ForegroundColor Red
                    return
                }

                & $script
            }
        }
    }
}
