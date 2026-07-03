# Toggle: Run Update Drivers (plain action launcher, no state recording).
# Converted from 'AtlasDesktop\2. Drivers\Run Update Drivers.cmd'.
#
# The original launcher ended with 'pause > null', creating a stray file named 'null'
# in the working directory; the engine's interactive pause replaces it.
@{
    Name          = 'UpdateDrivers'
    Elevation     = 'Admin'
    NoStateRecord = $true
    States        = [ordered]@{
        Run = @{
            Launcher = '2. Drivers\Run Update Drivers.cmd'
            Reboot   = 'None'
            Action   = {
                param($Toggle)

                $script = Join-Path -Path $Toggle.ScriptsPath -ChildPath 'Internal\UpdateDrivers.ps1'
                if (-not (Test-Path -LiteralPath $script -PathType Leaf)) {
                    Write-Host "Script not found: `"$script`"" -ForegroundColor Red
                    return
                }

                & $script
            }
        }
    }
}
