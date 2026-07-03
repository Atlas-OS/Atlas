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
                Remove-Item -Path "$env:LOCALAPPDATA\Microsoft\WindowsApps\python*.exe" -Force -ErrorAction SilentlyContinue
                if (Test-Path Alias:python) { Remove-Item Alias:python }
                if (Test-Path Alias:python3) { Remove-Item Alias:python3 }

                Write-Host '-----------------------------------------'
                Write-Host 'Cleanup completed.'
            }
        }
    }
}
