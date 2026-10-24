function Invoke-AtlasSoftwarePicker {
    param($Toggle)

    [void]$Toggle
    Import-AtlasModule -Name Atlas.Software
    if (-not (Show-AtlasSoftwarePicker)) {
        throw 'WinGet is not available, so no software was installed. Install App Installer from the Microsoft Store, then try again.'
    }
}
