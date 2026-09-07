function Test-AtlasNVidiaDisplayContainerInstalled {
    param($Toggle)

    return Test-Path -LiteralPath 'HKLM:\SYSTEM\CurrentControlSet\Services\NVDisplay.ContainerLocalSystem'
}

function Set-AtlasNVidiaDisplayContainerState {
    param($Toggle)

    if (-not (Test-AtlasNVidiaDisplayContainerInstalled -Toggle $Toggle)) {
        throw 'NVIDIA Display Container LS is not installed; the requested state is not applicable and was not recorded.'
    }

    $enable = $Toggle.State -ceq 'Enable'
    if (-not $enable -and -not $Toggle.Silent) {
        Write-AtlasWarning -Text @(
            'Disabling the NVIDIA Display Container LS service stops the NVIDIA Control Panel and'
            'most other NVIDIA driver features. It is meant for stripped drivers and people who'
            'rarely open the Control Panel; run the enable script to restore it.'
            "See 'Must Read First' in this folder for details."
        )
    }

    Set-AtlasServiceStartup -Name 'NVDisplay.ContainerLocalSystem' -StartupType $(if ($enable) { 2 } else { 4 })
    $service = Get-Service -Name 'NVDisplay.ContainerLocalSystem' -ErrorAction Stop
    if ($enable) {
        if ($service.Status -ne [ServiceProcess.ServiceControllerStatus]::Running) {
            Start-Service -InputObject $service -ErrorAction Stop
        }
    }
    elseif ($service.Status -ne [ServiceProcess.ServiceControllerStatus]::Stopped) {
        Stop-Service -InputObject $service -Force -ErrorAction Stop
    }
}
