@{
    Name          = 'RepairWindowsComponents'
    Description   = 'Repairs Windows components and system files with DISM RestoreHealth and SFC. Records no state.'
    Elevation     = 'Admin'
    NoStateRecord = $true
    Warning       = 'Repairs corrupt Windows components and system files with DISM and SFC. It can take a long time and needs an Internet connection for missing files. Atlas settings are not reverted.'
    Script        = 'RepairWindowsComponents.ps1'
    States        = @(
        @{
            Name            = 'Run'
            Launcher        = '9. Troubleshooting\Repair Windows Components.cmd'
            ToolboxLauncher = 'Scripts\Troubleshooting\Repair Windows Components.cmd'
            Reboot          = 'Recommend'
            MachineAction   = 'Repair-AtlasWindowsComponents'
        }
    )
}
