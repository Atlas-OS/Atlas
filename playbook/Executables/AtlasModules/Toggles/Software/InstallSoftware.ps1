# Companion for the InstallSoftware toggle: opens the Atlas software picker.
# Invoke-AtlasSoftwarePicker runs in the launcher's own process, as you, when you run the
# launcher; nothing is recorded.

function Invoke-AtlasSoftwarePicker {
    param($Toggle)

    [void]$Toggle
    Import-AtlasModule -Name Atlas.Software
    if (-not (Show-AtlasSoftwarePicker)) {
        throw 'WinGet is not available, so no software was installed. Install App Installer from the Microsoft Store, then try again.'
    }
}
