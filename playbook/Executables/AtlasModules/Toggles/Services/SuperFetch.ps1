# Toggle: SuperFetch / SysMain and ReadyBoost.
$action = {
    param($Toggle)

    Import-Module -Name (Join-Path $Toggle.ScriptsPath `
            'Modules\Atlas.Registry\Atlas.Registry.psd1') `
        -ErrorAction Stop

    $enable = $Toggle.State -ceq 'Enable'
    $classKey = 'HKLM:\SYSTEM\CurrentControlSet\Control\Class\{71a27cdd-812a-11d0-bec7-08002be2092f}'
    $properties = Get-ItemProperty -LiteralPath $classKey -ErrorAction Stop
    [string[]]$lowerFilters = if ($properties.PSObject.Properties.Name -contains 'LowerFilters') {
        @($properties.LowerFilters)
    }
    else {
        $null
    }

    if ($enable) {
        if ($null -eq $lowerFilters) {
            Set-AtlasRegistryValue -Path $classKey -Name 'LowerFilters' `
                -Type MultiString -Data ([string[]]@('rdyboost'))
        }
        elseif ($lowerFilters -notcontains 'rdyboost') {
            Set-AtlasRegistryValue -Path $classKey -Name 'LowerFilters' `
                -Type MultiString -Data ([string[]](@($lowerFilters) + 'rdyboost'))
        }
    }
    elseif ($null -ne $lowerFilters) {
        $lowerFilters = @($lowerFilters | Where-Object { $_ -and $_ -ne 'rdyboost' })
        if ($lowerFilters.Count -eq 0) {
            Remove-AtlasRegistryValue -Path $classKey -Name 'LowerFilters'
        }
        else {
            Set-AtlasRegistryValue -Path $classKey -Name 'LowerFilters' `
                -Type MultiString -Data ([string[]]$lowerFilters)
        }
    }

    $setServiceStartup = Join-Path -Path $Toggle.ScriptsPath `
        -ChildPath 'Internal\Set-ServiceStartup.ps1'
    $readyBoostStart = if ($enable) { 0 } else { 4 }
    & $setServiceStartup -Name 'rdyboost' -Start $readyBoostStart

    $readyBoostTab = 'HKLM:\SOFTWARE\Classes\Drive\shellex\PropertySheetHandlers\{55B3A0BD-4D28-42fe-8CFB-FA3EDFF969B8}'
    if ($enable) {
        New-AtlasRegistryKey -Path $readyBoostTab
    }
    else {
        Remove-AtlasRegistryKey -Path $readyBoostTab
    }

    $sysMainStart = if ($enable) { 2 } else { 4 }
    & $setServiceStartup -Name 'SysMain' -Start $sysMainStart
}

@{
    Name      = 'SuperFetch'
    Elevation = 'Admin'
    Warning   = 'WARNING: This script will modify system services. Modifying services can lead to potential breakage of features and bugs. Proceed with caution, and refer to Atlas docs for more information!'
    States    = [ordered]@{
        Disable = @{
            StateValue     = 0
            ReplayScope    = 'Machine'
            Launcher       = '6. Advanced Configuration\Services\Superfetch\Disable SuperFetch.cmd'
            ToolboxLauncher = 'Scripts\SuperFetch\DisableSuperFetch.cmd'
            Reboot         = 'Recommend'
            Action         = $action
        }
        Enable  = @{
            StateValue     = 1
            ReplayScope    = 'Machine'
            Launcher       = '6. Advanced Configuration\Services\Superfetch\Enable SuperFetch (default).cmd'
            ToolboxLauncher = 'Scripts\SuperFetch\EnableSuperFetch.cmd'
            Reboot         = 'Recommend'
            Action         = $action
        }
    }
}
