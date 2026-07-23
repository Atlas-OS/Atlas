# Toggle: Fullscreen Optimizations (FSO) and Game Bar / Game DVR support.
# Machine changes run as TrustedInstaller; current-user changes run in the caller's session.
$fsoGameBarMachineAction = {
    param($Toggle)

    Import-Module -Name (Join-Path -Path $Toggle.ScriptsPath `
            -ChildPath 'Modules\Atlas.Registry\Atlas.Registry.psd1') `
        -ErrorAction Stop

    $presenceKey = 'HKLM:\SOFTWARE\Microsoft\WindowsRuntime\ActivatableClassId\Windows.Gaming.GameBar.PresenceServer.Internal.PresenceWriter'
    $allowGameDvrKey = 'HKLM:\SOFTWARE\Microsoft\PolicyManager\default\ApplicationManagement\AllowGameDVR'

    switch -CaseSensitive ([string]$Toggle.State) {
        'Disable' {
            Set-AtlasRegistryValue `
                -Path 'HKLM:\SYSTEM\CurrentControlSet\Control\Session Manager\Environment' `
                -Name '__COMPAT_LAYER' -Type String `
                -Data '~ DISABLEDXMAXIMIZEDWINDOWEDMODE'
            Set-AtlasRegistryValue -Path $presenceKey -Name 'ActivationType' `
                -Type DWord -Data 0
            Set-AtlasRegistryValue `
                -Path 'HKLM:\SOFTWARE\Policies\Microsoft\Windows\GameDVR' `
                -Name 'AllowGameDVR' -Type DWord -Data 0
            Set-AtlasRegistryValue -Path $allowGameDvrKey -Name 'value' `
                -Type DWord -Data 0

            # Under TrustedInstaller/SYSTEM, -AllUsers is required on both commands.
            Get-AppxPackage -AllUsers '*xboxgamingoverlay*' -ErrorAction Stop |
                Remove-AppxPackage -AllUsers -Confirm:$false -ErrorAction Stop
        }
        'Enable' {
            Remove-AtlasRegistryValue `
                -Path 'HKLM:\SYSTEM\CurrentControlSet\Control\Session Manager\Environment' `
                -Name '__COMPAT_LAYER'
            Set-AtlasRegistryValue -Path $presenceKey -Name 'ActivationType' `
                -Type DWord -Data 1
            Remove-AtlasRegistryKey `
                -Path 'HKLM:\SOFTWARE\Policies\Microsoft\Windows\GameDVR'
            Set-AtlasRegistryValue -Path $allowGameDvrKey -Name 'value' `
                -Type DWord -Data 1
        }
        default { throw "FSOGameBar: unsupported state '$($Toggle.State)'." }
    }
}

$fsoGameBarUserAction = {
    param($Toggle)

    Import-Module -Name (Join-Path -Path $Toggle.ScriptsPath `
            -ChildPath 'Modules\Atlas.Registry\Atlas.Registry.psd1') `
        -ErrorAction Stop

    switch -CaseSensitive ([string]$Toggle.State) {
        'Disable' {
            Set-AtlasRegistryValue -Path 'HKCU:\System\GameConfigStore' -Name 'GameDVR_DSEBehavior' -Type DWord -Data 2
            Set-AtlasRegistryValue -Path 'HKCU:\System\GameConfigStore' -Name 'GameDVR_DXGIHonorFSEWindowsCompatible' -Type DWord -Data 1
            Set-AtlasRegistryValue -Path 'HKCU:\System\GameConfigStore' -Name 'GameDVR_EFSEFeatureFlags' -Type DWord -Data 0
            Set-AtlasRegistryValue -Path 'HKCU:\System\GameConfigStore' -Name 'GameDVR_FSEBehavior' -Type DWord -Data 2
            Set-AtlasRegistryValue -Path 'HKCU:\System\GameConfigStore' -Name 'GameDVR_FSEBehaviorMode' -Type DWord -Data 2
            Set-AtlasRegistryValue -Path 'HKCU:\System\GameConfigStore' -Name 'GameDVR_HonorUserFSEBehaviorMode' -Type DWord -Data 1
            Set-AtlasRegistryValue -Path 'HKCU:\SOFTWARE\Microsoft\GameBar' -Name 'GamePanelStartupTipIndex' -Type DWord -Data 3
            Set-AtlasRegistryValue -Path 'HKCU:\SOFTWARE\Microsoft\GameBar' -Name 'ShowStartupPanel' -Type DWord -Data 0
            Set-AtlasRegistryValue -Path 'HKCU:\SOFTWARE\Microsoft\GameBar' -Name 'UseNexusForGameBarEnabled' -Type DWord -Data 0
            Set-AtlasRegistryValue -Path 'HKCU:\System\GameConfigStore' -Name 'GameDVR_Enabled' -Type DWord -Data 0
            Set-AtlasRegistryValue -Path 'HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\GameDVR' -Name 'AppCaptureEnabled' -Type DWord -Data 0
        }
        'Enable' {
            $gameBarInstaller = Join-Path -Path $Toggle.ScriptsPath `
                -ChildPath 'Internal\Install-GameBar.ps1'
            if (-not (Test-Path -LiteralPath $gameBarInstaller -PathType Leaf)) {
                throw "FSOGameBar: the Game Bar installer is missing at '$gameBarInstaller'."
            }
            & $gameBarInstaller

            Remove-AtlasRegistryValue -Path 'HKCU:\System\GameConfigStore' -Name 'GameDVR_DSEBehavior'
            Set-AtlasRegistryValue -Path 'HKCU:\System\GameConfigStore' -Name 'GameDVR_DXGIHonorFSEWindowsCompatible' -Type DWord -Data 0
            Set-AtlasRegistryValue -Path 'HKCU:\System\GameConfigStore' -Name 'GameDVR_EFSEFeatureFlags' -Type DWord -Data 0
            Remove-AtlasRegistryValue -Path 'HKCU:\System\GameConfigStore' -Name 'GameDVR_FSEBehavior'
            Set-AtlasRegistryValue -Path 'HKCU:\System\GameConfigStore' -Name 'GameDVR_FSEBehaviorMode' -Type DWord -Data 2
            Set-AtlasRegistryValue -Path 'HKCU:\System\GameConfigStore' -Name 'GameDVR_HonorUserFSEBehaviorMode' -Type DWord -Data 0
            Remove-AtlasRegistryValue -Path 'HKCU:\SOFTWARE\Microsoft\GameBar' -Name 'GamePanelStartupTipIndex'
            Remove-AtlasRegistryValue -Path 'HKCU:\SOFTWARE\Microsoft\GameBar' -Name 'ShowStartupPanel'
            Remove-AtlasRegistryValue -Path 'HKCU:\SOFTWARE\Microsoft\GameBar' -Name 'UseNexusForGameBarEnabled'
            Set-AtlasRegistryValue -Path 'HKCU:\System\GameConfigStore' -Name 'GameDVR_Enabled' -Type DWord -Data 1
            Remove-AtlasRegistryValue -Path 'HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\GameDVR' -Name 'AppCaptureEnabled'
        }
        default { throw "FSOGameBar: unsupported state '$($Toggle.State)'." }
    }

    if (-not $Toggle.Silent) {
        $status = if ($Toggle.State -ceq 'Enable') { 'enabled' } else { 'disabled' }
        Write-Host "FSO and Game Bar have been $status."
    }
}

@{
    Name      = 'FSOGameBar'
    Elevation = 'TrustedInstaller'
    Warning   = 'WARNING: This script will modify system services. Modifying services can lead to potential breakage of features and bugs. Proceed with caution, and refer to Atlas docs for more information!'
    States    = [ordered]@{
        Disable = @{
            StateValue       = 0
            Launcher         = '3. General Configuration\FSO and Game Bar\Disable FSO and Game Bar Support.cmd'
            Reboot           = 'None'
            StateRecordScope = 'Machine'
            MachineAction    = $fsoGameBarMachineAction
            UserAction       = $fsoGameBarUserAction
        }
        Enable  = @{
            StateValue       = 1
            Launcher         = '3. General Configuration\FSO and Game Bar\Enable FSO and Game Bar Support (default).cmd'
            Reboot           = 'None'
            StateRecordScope = 'Machine'
            MachineAction    = $fsoGameBarMachineAction
            UserAction       = $fsoGameBarUserAction
        }
    }
}
