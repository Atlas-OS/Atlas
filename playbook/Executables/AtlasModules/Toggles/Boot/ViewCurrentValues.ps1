# Toggle: View the current boot configuration values (read-only info action).
# Converted from 'AtlasDesktop\6. Advanced Configuration\Boot Configuration\View Current Values.cmd'.
# Purely prints 'bcdedit /enum {current}' output; records no state.
@{
    Name          = 'ViewCurrentValues'
    Elevation     = 'Admin'
    NoStateRecord = $true
    States        = [ordered]@{
        View = @{
            Launcher = '6. Advanced Configuration\Boot Configuration\View Current Values.cmd'
            Reboot   = 'None'
            Action   = {
                param($Toggle)

                $output = & "$($Toggle.WinDir)\System32\bcdedit.exe" /enum '{current}'
                $output | Select-Object -Skip 3 | ForEach-Object { Write-Host $_ }
            }
        }
    }
}
