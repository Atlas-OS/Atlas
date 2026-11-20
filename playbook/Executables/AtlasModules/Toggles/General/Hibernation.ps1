# Companion for the Hibernation toggle: turns hibernation on or off with powercfg.
# Set-AtlasHibernationPowerState runs as Administrator when you run a launcher, when the
# install applies your hibernation choice and when an update replays the recorded state.

function Set-AtlasHibernationPowerState {
    param($Toggle)

    $enabled = switch -CaseSensitive ([string]$Toggle.State) {
        'Disable' { $false }
        'Enable' { $true }
        default { throw "Hibernation: unsupported state '$($Toggle.State)'." }
    }

    $powercfg = Join-Path -Path $Toggle.WinDir -ChildPath 'System32\powercfg.exe'
    if (-not (Test-Path -LiteralPath $powercfg -PathType Leaf)) {
        throw "Hibernation: powercfg.exe is missing at '$powercfg'."
    }

    $powercfgState = if ($enabled) { 'on' } else { 'off' }
    Invoke-AtlasToggleNativeCommand `
        -FilePath $powercfg `
        -ArgumentList ([string[]]@('/hibernate', $powercfgState)) `
        -AllowedExitCodes ([int[]]@(0)) | Out-Null
}
