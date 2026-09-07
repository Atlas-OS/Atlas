function Set-AtlasSuperFetchMachineState {
    param($Toggle)

    $enable = $Toggle.State -ceq 'Enable'

    # ReadyBoost is a volume lower filter; add or remove only its own entry.
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

    $readyBoostStart = if ($enable) { 0 } else { 4 }
    Set-AtlasServiceStartup -Name 'rdyboost' -StartupType $readyBoostStart

    $readyBoostTab = 'HKLM:\SOFTWARE\Classes\Drive\shellex\PropertySheetHandlers\{55B3A0BD-4D28-42fe-8CFB-FA3EDFF969B8}'
    if ($enable) {
        New-AtlasRegistryKey -Path $readyBoostTab
    }
    else {
        Remove-AtlasRegistryKey -Path $readyBoostTab
    }

    $sysMainStart = if ($enable) { 2 } else { 4 }
    Set-AtlasServiceStartup -Name 'SysMain' -StartupType $sysMainStart
}
