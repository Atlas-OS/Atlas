# Disables unused control center / quick action items by default. Explorer is stopped
# first so it does not overwrite the quick action state on exit, then restarted.
# The quick action names and toggle data differ between Windows 10 and Windows 11, so
# this branches on the build number, which the declarative Registry schema cannot do.
$ErrorActionPreference = 'Stop'

if (-not (Get-Command -Name 'Set-AtlasRegistryValue' -ErrorAction SilentlyContinue)) {
    Import-Module -Name 'Atlas.Registry' -Force
}

Stop-Process -Name 'explorer' -Force -ErrorAction SilentlyContinue

$unpinnedPath = 'HKCU\Control Panel\Quick Actions\Control Center\Unpinned'
$togglesPath = 'HKCU\Control Panel\Quick Actions\Control Center\QuickActionsStateCapture'

if ([System.Environment]::OSVersion.Version.Build -ge 22000) {
    # Windows 11
    foreach ($quickAction in @('Microsoft.QuickAction.Cast', 'Microsoft.QuickAction.NearShare')) {
        Set-AtlasRegistryValue -Path $unpinnedPath -Name $quickAction -Type 'None'
    }

    Set-AtlasRegistryValue -Path $togglesPath -Name 'Toggles' -Type 'String' `
        -Data 'Toggles,Microsoft.QuickAction.BlueLightReduction:false,Microsoft.QuickAction.Accessibility:false,Microsoft.QuickAction.ProjectL2:false'
}
else {
    # Windows 10
    foreach ($quickAction in @('Microsoft.QuickAction.Connect', 'Microsoft.QuickAction.Location', 'Microsoft.QuickAction.ScreenClipping')) {
        Set-AtlasRegistryValue -Path $unpinnedPath -Name $quickAction -Type 'None'
    }

    Set-AtlasRegistryValue -Path $togglesPath -Name 'Toggles' -Type 'String' `
        -Data 'Toggles,Microsoft.QuickAction.BlueLightReduction:false,Microsoft.QuickAction.AllSettings:false,Microsoft.QuickAction.Project:false'
}

# The tweak engine restarts explorer from the installer's context.
Start-Process -FilePath 'explorer.exe'
