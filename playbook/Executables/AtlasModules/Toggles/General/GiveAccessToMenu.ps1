# Toggle: 'Give access to' (Sharing) context menu entries.
@{
    Name      = 'GiveAccessToMenu'
    Elevation = 'Admin'
    States    = [ordered]@{
        Disable = @{
            StateValue = 0
            Launcher   = '3. General Configuration\File Sharing\Give Access To Menu\Disable Give Access To Menu (default).cmd'
            Reboot     = 'None'
            Action     = {
                param($Toggle)

                Import-Module -Name (Join-Path $Toggle.ScriptsPath 'Modules\Atlas.Registry\Atlas.Registry.psd1') -Force -ErrorAction Stop
                foreach ($key in @(
                    'Registry::HKEY_CLASSES_ROOT\*\shellex\ContextMenuHandlers\Sharing'
                    'Registry::HKEY_CLASSES_ROOT\Directory\Background\shellex\ContextMenuHandlers\Sharing'
                    'Registry::HKEY_CLASSES_ROOT\Directory\shellex\ContextMenuHandlers\Sharing'
                    'Registry::HKEY_CLASSES_ROOT\Drive\shellex\ContextMenuHandlers\Sharing'
                    'Registry::HKEY_CLASSES_ROOT\LibraryFolder\background\shellex\ContextMenuHandlers\Sharing'
                    'Registry::HKEY_CLASSES_ROOT\UserLibraryFolder\shellex\ContextMenuHandlers\Sharing'
                )) {
                    Remove-AtlasRegistryKey -Path $key
                }

                if (-not $Toggle.Silent) {
                    Write-Host "Finished, 'Give Access To' menu is now disabled."
                }
            }
        }
        Enable  = @{
            StateValue = 1
            Launcher   = '3. General Configuration\File Sharing\Give Access To Menu\Enable Give Access To Menu.cmd'
            Reboot     = 'None'
            Action     = {
                param($Toggle)

                foreach ($key in @(
                    'Registry::HKEY_CLASSES_ROOT\*\shellex\ContextMenuHandlers\Sharing'
                    'Registry::HKEY_CLASSES_ROOT\Directory\Background\shellex\ContextMenuHandlers\Sharing'
                    'Registry::HKEY_CLASSES_ROOT\Directory\shellex\ContextMenuHandlers\Sharing'
                    'Registry::HKEY_CLASSES_ROOT\Drive\shellex\ContextMenuHandlers\Sharing'
                    'Registry::HKEY_CLASSES_ROOT\LibraryFolder\background\shellex\ContextMenuHandlers\Sharing'
                    'Registry::HKEY_CLASSES_ROOT\UserLibraryFolder\shellex\ContextMenuHandlers\Sharing'
                )) {
                    if (-not (Test-Path -LiteralPath $key)) { New-Item -Path $key -Force | Out-Null }
                    New-ItemProperty -LiteralPath $key -Name '(default)' -Value '{f81e9010-6ea4-11ce-a7ff-00aa003ca9f6}' -PropertyType String -Force | Out-Null
                }

                if (-not $Toggle.Silent) {
                    Write-Host "Finished, 'Give Access To' menu is now enabled."
                }
            }
        }
    }
}
