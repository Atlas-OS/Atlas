# Toggle: Edge Swipe gesture (touch screen edge swipe).
@{
    Name      = 'EdgeSwipe'
    Elevation = 'Admin'
    States    = [ordered]@{
        Allow    = @{
            StateValue = 1
            ReplayScope = 'Machine'
            Launcher   = '4. Interface Tweaks\Edge Swipe\Allow Edge Swipe (default).cmd'
            Reboot     = 'None'
            Action     = {
                param($Toggle)

                Import-Module -Name (Join-Path $Toggle.ScriptsPath 'Modules\Atlas.Registry\Atlas.Registry.psd1') -ErrorAction Stop
                Remove-AtlasRegistryValue -Path 'HKLM:\SOFTWARE\Policies\Microsoft\Windows\EdgeUI' -Name 'AllowEdgeSwipe'

                if (-not $Toggle.Silent) {
                    Write-Host 'Changes applied successfully.'
                }
            }
        }
        Disallow = @{
            StateValue = 0
            ReplayScope = 'Machine'
            Launcher   = '4. Interface Tweaks\Edge Swipe\Disallow Edge Swipe.cmd'
            Reboot     = 'None'
            Action     = {
                param($Toggle)

                $key = 'HKLM:\SOFTWARE\Policies\Microsoft\Windows\EdgeUI'
                if (-not (Test-Path -LiteralPath $key)) {
                    New-Item -Path $key -Force | Out-Null
                }
                New-ItemProperty -LiteralPath $key -Name 'AllowEdgeSwipe' -Value 0 -PropertyType DWord -Force | Out-Null

                if (-not $Toggle.Silent) {
                    Write-Host 'Changes applied successfully.'
                }
            }
        }
    }
}
