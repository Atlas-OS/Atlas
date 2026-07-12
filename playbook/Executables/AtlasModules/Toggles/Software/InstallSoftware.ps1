# Toggle: Install Software (plain action launcher, no state recording).
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
                    throw "InstallSoftware: the protected picker entry point is missing at '$script'."
                }

                & $script
            }
        }
    }
}
