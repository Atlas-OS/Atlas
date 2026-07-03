# Toggle: Process Explorer (replace Task Manager with Sysinternals Process Explorer).
#
# Interactive installs prompt before disabling the pcw service; silent installs
# disable it unconditionally.
@{
    Name      = 'ProcessExplorer'
    Elevation = 'Admin'
    States    = [ordered]@{
        Install   = @{
            StateValue = 1
            Launcher   = '6. Advanced Configuration\Process Explorer\Install Process Explorer.cmd'
            Reboot     = 'None'
            Action     = {
                param($Toggle)

                $wingetCheck = Join-Path -Path $Toggle.ScriptsPath -ChildPath 'Test-Winget.cmd'
                & "$env:ComSpec" /c "call `"$wingetCheck`""
                if ($LASTEXITCODE -ne 0) {
                    Write-AtlasLog -Level Warning -Message 'ProcessExplorer: winget is not functional; cannot install.'
                    return
                }

                $appDir = Join-Path -Path $Toggle.AtlasModulesPath -ChildPath 'Apps\ProcessExplorer'
                Write-Host 'Installing Process Explorer...'
                winget install -e --id Microsoft.Sysinternals.ProcessExplorer --uninstall-previous -l "$appDir" -h --accept-source-agreements --accept-package-agreements --force --disable-interactivity | Out-Null
                if ($LASTEXITCODE -ne 0) {
                    Write-AtlasLog -Level Warning -Message 'ProcessExplorer: winget installation failed.'
                    return
                }

                Write-Host 'Creating the Start menu shortcut...'
                $shortcut = Join-Path ([Environment]::GetFolderPath('CommonStartMenu')) 'Programs\Process Explorer.lnk'
                $wsh = New-Object -ComObject WScript.Shell
                $lnk = $wsh.CreateShortcut($shortcut)
                $lnk.TargetPath = Join-Path -Path $appDir -ChildPath 'procexp.exe'
                $lnk.Save()

                Write-Host 'Configuring Process Explorer...'
                Set-ItemProperty 'HKCU:\SOFTWARE\Sysinternals\Process Explorer' -Name 'OneInstance' -Value 1 -Type DWord -Force
                $ifeo = 'HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Image File Execution Options\taskmgr.exe'
                if (-not (Test-Path -LiteralPath $ifeo)) { New-Item -Path $ifeo -Force | Out-Null }
                Set-ItemProperty -LiteralPath $ifeo -Name 'Debugger' -Value (Join-Path -Path $appDir -ChildPath 'procexp.exe') -Type String -Force

                $disablePcw = $true
                if (-not $Toggle.Silent) {
                    Write-Host ''
                    Write-Host "The 'pcw' service is needed for Task Manager and performance counters."
                    Write-Host 'Disabling it matters less with Process Explorer, but some software may misbehave.'
                    $answer = Read-Host 'Would you like to disable it? [Y/N]'
                    $disablePcw = ($answer -match '^(y|yes)$')
                }
                if ($disablePcw) {
                    & "$($Toggle.WinDir)\System32\sc.exe" config pcw start=disabled | Out-Null
                }

                if (-not $Toggle.Silent) { Write-Host 'Finished, changes have been applied.' }
            }
        }
        Uninstall = @{
            StateValue = 0
            Launcher   = '6. Advanced Configuration\Process Explorer\Uninstall Process Explorer.cmd'
            Reboot     = 'None'
            Action     = {
                param($Toggle)

                $wingetCheck = Join-Path -Path $Toggle.ScriptsPath -ChildPath 'Test-Winget.cmd'
                & "$env:ComSpec" /c "call `"$wingetCheck`" /silent"
                if ($LASTEXITCODE -eq 0) {
                    winget uninstall -e --id Microsoft.Sysinternals.ProcessExplorer --force --purge --disable-interactivity --accept-source-agreements -h | Out-Null
                }
                else {
                    Write-AtlasLog -Level Warning -Message 'ProcessExplorer: winget not functional; reverting other changes anyway.'
                }

                & "$($Toggle.WinDir)\System32\sc.exe" config pcw start=boot | Out-Null
                $ifeo = 'HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Image File Execution Options\taskmgr.exe'
                Remove-ItemProperty -LiteralPath $ifeo -Name 'Debugger' -Force -ErrorAction SilentlyContinue
                Remove-Item -LiteralPath (Join-Path ([Environment]::GetFolderPath('CommonStartMenu')) 'Programs\Process Explorer.lnk') -Force -ErrorAction SilentlyContinue

                if ($Toggle.Silent) {
                    Stop-Process -Name taskmgr -Force -ErrorAction SilentlyContinue
                    return
                }
                if (-not $Toggle.Silent) { Write-Host 'Finished, changes have been applied.' }
            }
        }
    }
}
