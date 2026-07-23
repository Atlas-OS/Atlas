# Toggle: Hibernation (powercfg /hibernate + Start flyout hibernate option).
$hibernationAction = {
    param($Toggle)

    $enabled = switch -CaseSensitive ([string]$Toggle.State) {
        'Disable' { $false }
        'Enable' { $true }
        default { throw "Hibernation: unsupported state '$($Toggle.State)'." }
    }

    Import-Module -Name (Join-Path -Path $Toggle.ScriptsPath `
            -ChildPath 'Modules\Atlas.Registry\Atlas.Registry.psd1') `
        -ErrorAction Stop

    $powercfg = Join-Path -Path $Toggle.WinDir -ChildPath 'System32\powercfg.exe'
    if (-not (Test-Path -LiteralPath $powercfg -PathType Leaf)) {
        throw "Hibernation: powercfg.exe is missing at '$powercfg'."
    }

    $powercfgState = if ($enabled) { 'on' } else { 'off' }
    Invoke-AtlasToggleNativeCommand `
        -FilePath $powercfg `
        -ArgumentList ([string[]]@('/hibernate', $powercfgState)) `
        -AllowedExitCodes ([int[]]@(0)) | Out-Null

    Set-AtlasRegistryValue `
        -Path 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\FlyoutMenuSettings' `
        -Name 'ShowHibernateOption' -Type DWord -Data ([int]$enabled)

    if (-not $Toggle.Silent) {
        $status = if ($enabled) { 'enabled' } else { 'disabled' }
        Write-Host "Hibernation has been $status."
    }
}

@{
    Name      = 'Hibernation'
    Elevation = 'Admin'
    States    = [ordered]@{
        Disable = @{
            StateValue = 0
            ReplayScope = 'Machine'
            Launcher   = '3. General Configuration\Hibernation\Disable Hibernation (default).cmd'
            Reboot     = 'Prompt'
            Action     = $hibernationAction
        }
        Enable  = @{
            StateValue = 1
            ReplayScope = 'Machine'
            Launcher   = '3. General Configuration\Hibernation\Enable Hibernation.cmd'
            Reboot     = 'None'
            Action     = $hibernationAction
        }
    }
}
