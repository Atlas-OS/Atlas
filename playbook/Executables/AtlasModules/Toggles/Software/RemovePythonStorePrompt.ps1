# Toggle: Remove the Microsoft Store "Python" app-execution alias stubs (no state recording).
@{
    Name          = 'RemovePythonStorePrompt'
    Elevation     = 'None'
    NoStateRecord = $true
    States        = [ordered]@{
        Run = @{
            Launcher = '1. Software\Remove Python Store Prompt.cmd'
            Reboot   = 'None'
            Action   = {
                param($Toggle)

                Write-Host 'Attempting to remove Python executables from WindowsApps...'
                $localAppData = [Environment]::GetFolderPath(
                    [Environment+SpecialFolder]::LocalApplicationData
                )
                if ([string]::IsNullOrWhiteSpace($localAppData)) {
                    throw 'The current user has no LocalApplicationData known-folder path.'
                }
                $windowsApps = [IO.Path]::GetFullPath(
                    [IO.Path]::Combine($localAppData, 'Microsoft', 'WindowsApps')
                )
                if ([IO.Directory]::Exists($windowsApps)) {
                    $aliases = @(Get-ChildItem -LiteralPath $windowsApps `
                            -Filter 'python*.exe' -File -Force -ErrorAction Stop)
                    foreach ($alias in $aliases) {
                        Remove-Item -LiteralPath $alias.FullName -Force `
                            -ErrorAction Stop
                        if ([IO.File]::Exists($alias.FullName)) {
                            throw "Python app-execution alias was not removed: '$($alias.FullName)'."
                        }
                    }
                    Write-Host "Removed $($aliases.Count) Python app-execution alias(es)."
                }
                else {
                    Write-Host 'The current user has no WindowsApps alias directory; nothing to remove.'
                }

                Write-Host '-----------------------------------------'
                Write-Host 'Cleanup completed.'
            }
        }
    }
}
