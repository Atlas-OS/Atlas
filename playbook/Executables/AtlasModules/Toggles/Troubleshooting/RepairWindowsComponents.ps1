# Toggle: Repair Windows components / system files (DISM RestoreHealth + SFC, no state).
# Converted from 'AtlasDesktop\9. Troubleshooting\Repair Windows Components.cmd' (also surfaced
# in the Toolbox). The original had no settingName header and recorded no AtlasOS\Services
# state, so this is a NoStateRecord single-action ('Run') toggle. The pre-run confirmation is
# the engine's Warning surface (skipped under /silent, like the original's guarded pause).
@{
    Name          = 'RepairWindowsComponents'
    Elevation     = 'Admin'
    NoStateRecord = $true
    Warning       = "This will repair and replace any corrupt Windows components and system files.`nFor general issues, this might be a fix. Note that no components of Atlas is reverted with this."
    States        = [ordered]@{
        Run = @{
            Launcher        = '9. Troubleshooting\Repair Windows Components.cmd'
            ToolboxLauncher = 'Scripts\Troubleshooting\Repair Windows Components.cmd'
            Reboot          = 'Recommend'
            Action          = {
                param($Toggle)

                $dashes = '----------------------------------------------'
                Write-Host 'This might take a while.'

                Write-Host ''
                Write-Host $dashes
                Write-Host 'Restoring the component store...'
                Write-Host $dashes
                & "$($Toggle.WinDir)\System32\dism.exe" /online /cleanup-image /restorehealth

                Write-Host ''
                Write-Host $dashes
                Write-Host 'Restoring system files...'
                Write-Host $dashes
                & "$($Toggle.WinDir)\System32\sfc.exe" /scannow
            }
        }
    }
}
