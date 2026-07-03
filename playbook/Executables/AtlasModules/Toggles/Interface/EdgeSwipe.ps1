# Toggle: Edge Swipe gesture (touch screen edge swipe).
@{
    Name      = 'EdgeSwipe'
    Elevation = 'Admin'
    States    = [ordered]@{
        Allow    = @{
            StateValue = 1
            Launcher   = '4. Interface Tweaks\Edge Swipe\Allow Edge Swipe (default).cmd'
            Reboot     = 'None'
            Action     = {
                param($Toggle)

                Remove-ItemProperty -LiteralPath 'HKLM:\SOFTWARE\Policies\Microsoft\Windows\EdgeUI' -Name 'AllowEdgeSwipe' -Force -ErrorAction SilentlyContinue

                if (-not $Toggle.Silent) {
                    Write-Host 'Changes applied successfully.'
                }
            }
        }
        Disallow = @{
            StateValue = 0
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
