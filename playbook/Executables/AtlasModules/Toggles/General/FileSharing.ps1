# Toggle: File Sharing (network discovery, SMB, NetBIOS bindings).
# Fresh install and this toggle share the same Internal helpers; the engine owns
# the restart prompt and records only the completed machine transition.
$machineAction = {
    param($Toggle)

    $enable = $Toggle.State -ceq 'Enable'
    $verb = if ($enable) { 'Enable' } else { 'Disable' }
    $script = Join-Path $Toggle.ScriptsPath "Internal\$verb-FileSharing.ps1"
    $parameters = @{ Silent = [bool]$Toggle.Silent }
    if ($enable) {
        $parameters['StateRoot'] = $Toggle.StateRoot
    }
    & $script @parameters

    if (-not $Toggle.Silent) {
        $stateText = if ($enable) { 'enabled' } else { 'disabled' }
        Write-Host "Finished, File Sharing is now $stateText."
    }
}

$userAction = {
    param($Toggle)

    $networkClsid = 'HKCU:\SOFTWARE\Classes\CLSID\{F02C1A0D-BE21-4350-88B0-7367FC96EF3C}'
    if ($Toggle.State -ceq 'Enable') {
        # The recorded state does not capture this optional Explorer preference,
        # so silent replay leaves the current user's choice untouched.
        if ($Toggle.Silent -or
            (Read-Host 'Would you like to add Network to the Explorer navigation pane? [Y/N]') `
                -notmatch '^(y|yes)$') {
            return
        }
        Import-Module -Name (Join-Path $Toggle.ScriptsPath `
                'Modules\Atlas.Registry\Atlas.Registry.psd1') -Force -ErrorAction Stop
        Remove-AtlasRegistryValue -Path $networkClsid `
            -Name 'System.IsPinnedToNameSpaceTree'
        return
    }

    Import-Module -Name (Join-Path $Toggle.ScriptsPath `
            'Modules\Atlas.Registry\Atlas.Registry.psd1') -Force -ErrorAction Stop
    Set-AtlasRegistryValue -Path $networkClsid `
        -Name 'System.IsPinnedToNameSpaceTree' -Type DWord -Data 0
}

@{
    Name      = 'FileSharing'
    Elevation = 'Admin'
    States    = [ordered]@{
        Disable = @{
            StateValue       = 0
            Launcher         = '3. General Configuration\File Sharing\Disable File Sharing (default).cmd'
            ToolboxLauncher  = 'ConfigurationServices\FIleSharing\disable.cmd'
            Reboot           = 'Prompt'
            StateRecordScope = 'Machine'
            MachineAction    = $machineAction
            UserAction       = $userAction
        }
        Enable  = @{
            StateValue       = 1
            Launcher         = '3. General Configuration\File Sharing\Enable File Sharing.cmd'
            ToolboxLauncher  = 'ConfigurationServices\FIleSharing\enable.cmd'
            Reboot           = 'Prompt'
            StateRecordScope = 'Machine'
            MachineAction    = $machineAction
            UserAction       = $userAction
        }
    }
}
