@{
    Name        = 'NVidiaDisplayContainer'
    Description = 'NVIDIA Display Container LS service. Both states apply only while the service is installed, so a recorded state is dropped on upgrade once the driver is gone.'
    Elevation   = 'Admin'
    Warning     = 'Changes the NVIDIA Display Container LS service. While disabled, the NVIDIA Control Panel and most NVIDIA driver features stop working.'
    Script      = 'NVidiaDisplayContainer.ps1'
    States      = @(
        @{
            Name             = 'Disable'
            StateValue       = 0
            Launcher         = '6. Advanced Configuration\Services\NVIDIA Display Container\Disable NVIDIA Display Container LS.cmd'
            ToolboxLauncher  = 'Scripts\NVidia\DisableNVIDIADisplayContainerLS.cmd'
            Reboot           = 'None'
            MachineAction    = 'Set-AtlasNVidiaDisplayContainerState'
            ReplayApplicable = 'Test-AtlasNVidiaDisplayContainerInstalled'
        }
        @{
            Name             = 'Enable'
            StateValue       = 1
            Launcher         = '6. Advanced Configuration\Services\NVIDIA Display Container\Enable NVIDIA Display Container LS (default).cmd'
            ToolboxLauncher  = 'Scripts\NVidia\EnableNVIDIADisplayContainerLS.cmd'
            Reboot           = 'None'
            MachineAction    = 'Set-AtlasNVidiaDisplayContainerState'
            ReplayApplicable = 'Test-AtlasNVidiaDisplayContainerInstalled'
        }
    )
}
