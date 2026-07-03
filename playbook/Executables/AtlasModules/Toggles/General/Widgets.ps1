# Toggle: Widgets / News and Interests feeds.
#
# Test-EdgeState.cmd (which prompts to install Edge) and the ms-settings:taskbar page are
# gated to interactive mode so upgrade re-apply never blocks.
@{
    Name      = 'Widgets'
    Elevation = 'Admin'
    States    = [ordered]@{
        Disable = @{
            StateValue = 0
            Launcher   = '3. General Configuration\Widgets (News and Interests)\Disable Widgets (default).cmd'
            Reboot     = 'None'
            Action     = {
                param($Toggle)

                if (-not $Toggle.Silent) {
                    Write-Host ''
                    Write-Host 'Disabling News and Interests (called Widgets in Windows 11)...'
                }

                $feeds = 'HKLM:\SOFTWARE\Policies\Microsoft\Windows\Windows Feeds'
                if (-not (Test-Path -LiteralPath $feeds)) { New-Item -Path $feeds -Force | Out-Null }
                New-ItemProperty -LiteralPath $feeds -Name 'EnableFeeds' -Value 0 -PropertyType DWord -Force | Out-Null

                $dsh = 'HKLM:\SOFTWARE\Policies\Microsoft\Dsh'
                if (-not (Test-Path -LiteralPath $dsh)) { New-Item -Path $dsh -Force | Out-Null }
                New-ItemProperty -LiteralPath $dsh -Name 'AllowNewsAndInterests' -Value 0 -PropertyType DWord -Force | Out-Null

                if (-not $Toggle.NoExplorerRestart) {
                    Stop-Process -Name 'explorer' -Force -ErrorAction SilentlyContinue
                }

                if (-not $Toggle.Silent) {
                    Write-Host ''
                    Write-Host 'Finished, changes have been applied.'
                }
            }
        }
        Enable  = @{
            StateValue = 1
            Launcher   = '3. General Configuration\Widgets (News and Interests)\Enable Widgets.cmd'
            Reboot     = 'None'
            Action     = {
                param($Toggle)

                if (-not $Toggle.Silent) {
                    $edgeCheck = Join-Path -Path $Toggle.ScriptsPath -ChildPath 'Test-EdgeState.cmd'
                    & "$env:ComSpec" /c "call `"$edgeCheck`""
                    if ($LASTEXITCODE -ne 0) { return }

                    Write-Host ''
                    Write-Host 'Enabling News and Interests (called Widgets in Windows 11)...'
                }

                Remove-ItemProperty -LiteralPath 'HKLM:\SOFTWARE\Policies\Microsoft\Windows\Windows Feeds' -Name 'EnableFeeds' -Force -ErrorAction SilentlyContinue
                Remove-ItemProperty -LiteralPath 'HKLM:\SOFTWARE\Policies\Microsoft\Dsh' -Name 'AllowNewsAndInterests' -Force -ErrorAction SilentlyContinue

                Stop-Process -Name 'explorer' -Force -ErrorAction SilentlyContinue

                if (-not $Toggle.Silent) {
                    Start-Sleep -Seconds 3
                    Start-Process 'ms-settings:taskbar'
                    Write-Host ''
                    Write-Host 'Finished, you should be able to toggle News and Interests or Widgets in Settings.'
                }
            }
        }
    }
}
