# Disables unused control center / quick action items by default. Explorer is stopped
# first so it does not overwrite the quick action state on exit, then restarted.
# Kept as a script (not declarative Registry entries) because the toggle data is a
# single packed string that may need per-build variants in the future.
$ErrorActionPreference = 'Stop'

if (-not (Get-Command -Name 'Set-AtlasRegistryValue' -ErrorAction SilentlyContinue)) {
    Import-Module -Name 'Atlas.Registry' -Force
}

Stop-Process -Name 'explorer' -Force -ErrorAction SilentlyContinue

$unpinnedPath = 'HKCU\Control Panel\Quick Actions\Control Center\Unpinned'
$togglesPath = 'HKCU\Control Panel\Quick Actions\Control Center\QuickActionsStateCapture'

foreach ($quickAction in @('Microsoft.QuickAction.Cast', 'Microsoft.QuickAction.NearShare')) {
    Set-AtlasRegistryValue -Path $unpinnedPath -Name $quickAction -Type 'None'
}

Set-AtlasRegistryValue -Path $togglesPath -Name 'Toggles' -Type 'String' `
    -Data 'Toggles,Microsoft.QuickAction.BlueLightReduction:false,Microsoft.QuickAction.Accessibility:false,Microsoft.QuickAction.ProjectL2:false'

# The tweak engine restarts explorer from the installer's context.
Start-Process -FilePath 'explorer.exe'
