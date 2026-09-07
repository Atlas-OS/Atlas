function Add-AtlasNVidiaContainerContextMenu {
    param($Toggle)

    if (-not (Test-Path -LiteralPath 'HKLM:\SYSTEM\CurrentControlSet\Services\NVDisplay.ContainerLocalSystem')) {
        throw 'NVIDIA Display Container LS is not installed; its context menu cannot be added and no state was recorded.'
    }

    # The verb lives under the machine HKCR view. Each submenu entry launches the
    # matching AtlasDesktop launcher, so the command paths depend on the Windows root.
    $launcherRoot = Join-Path -Path $Toggle.WinDir -ChildPath 'AtlasDesktop\6. Advanced Configuration\Services\NVIDIA Display Container'
    $root = 'HKLM:\SOFTWARE\Classes\DesktopBackground\Shell\NVIDIAContainer'
    Set-AtlasRegistryValue -Path $root -Name 'Icon' -Type String -Data 'NVIDIA.ico,0'
    Set-AtlasRegistryValue -Path $root -Name 'MUIVerb' -Type String -Data 'NVIDIA Container'
    Set-AtlasRegistryValue -Path $root -Name 'Position' -Type String -Data 'Bottom'
    Set-AtlasRegistryValue -Path $root -Name 'SubCommands' -Type String -Data ''

    foreach ($entry in @(
            @{ Key = 'NVIDIAContainer001'; Label = 'Enable NVIDIA Display Container LS'; Launcher = 'Enable NVIDIA Display Container LS (default).cmd' }
            @{ Key = 'NVIDIAContainer002'; Label = 'Disable NVIDIA Display Container LS'; Launcher = 'Disable NVIDIA Display Container LS.cmd' }
        )) {
        $entryKey = "$root\shell\$($entry.Key)"
        Set-AtlasRegistryValue -Path $entryKey -Name 'HasLUAShield' -Type String -Data ''
        Set-AtlasRegistryValue -Path $entryKey -Name 'MUIVerb' -Type String -Data $entry.Label
        Set-AtlasRegistryValue -Path "$entryKey\command" -Name '' -Type String `
            -Data ('"{0}"' -f (Join-Path -Path $launcherRoot -ChildPath $entry.Launcher))
    }
}
