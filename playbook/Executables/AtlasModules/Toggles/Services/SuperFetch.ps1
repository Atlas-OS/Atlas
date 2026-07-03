# Toggle: SuperFetch / SysMain and ReadyBoost.
# Converted from 'AtlasDesktop\6. Advanced Configuration\Services\Superfetch\*.cmd'.
@{
    Name      = 'SuperFetch'
    Elevation = 'Admin'
    Warning   = 'WARNING: This script will modify system services. Modifying services can lead to potential breakage of features and bugs. Proceed with caution, and refer to Atlas docs for more information!'
    States    = [ordered]@{
        Disable = @{
            StateValue = 0
            Launcher   = '6. Advanced Configuration\Services\Superfetch\Disable SuperFetch.cmd'
            Reboot     = 'Recommend'
            Action     = {
                param($Toggle)

                # Remove the lower filter for the rdyboost driver from the volume class key
                $classKey = 'HKLM:\SYSTEM\CurrentControlSet\Control\Class\{71a27cdd-812a-11d0-bec7-08002be2092f}'
                $lowerFilters = (Get-ItemProperty -LiteralPath $classKey -Name 'LowerFilters' -ErrorAction SilentlyContinue).LowerFilters
                if ($null -ne $lowerFilters) {
                    $filtered = @($lowerFilters | Where-Object { $_ -and $_ -ne 'rdyboost' })
                    if ($filtered.Count -gt 0) {
                        New-ItemProperty -LiteralPath $classKey -Name 'LowerFilters' -Value ([string[]]$filtered) -PropertyType MultiString -Force | Out-Null
                    }
                    else {
                        Remove-ItemProperty -LiteralPath $classKey -Name 'LowerFilters' -Force -ErrorAction SilentlyContinue
                    }
                }

                # Disable ReadyBoost
                New-ItemProperty -LiteralPath 'HKLM:\SYSTEM\CurrentControlSet\Services\rdyboost' -Name 'Start' -Value 4 -PropertyType DWord -Force | Out-Null

                # Remove the ReadyBoost tab
                Remove-Item -Path 'Registry::HKEY_CLASSES_ROOT\Drive\shellex\PropertySheetHandlers\{55B3A0BD-4D28-42fe-8CFB-FA3EDFF969B8}' -Recurse -Force -ErrorAction SilentlyContinue

                # Disable SysMain (Prefetch, Memory Management features)
                New-ItemProperty -LiteralPath 'HKLM:\SYSTEM\CurrentControlSet\Services\SysMain' -Name 'Start' -Value 4 -PropertyType DWord -Force | Out-Null
            }
        }
        Enable  = @{
            StateValue = 1
            Launcher   = '6. Advanced Configuration\Services\Superfetch\Enable SuperFetch (default).cmd'
            Reboot     = 'Recommend'
            Action     = {
                param($Toggle)

                # Add the lower filter for the rdyboost driver to the volume class key
                $classKey = 'HKLM:\SYSTEM\CurrentControlSet\Control\Class\{71a27cdd-812a-11d0-bec7-08002be2092f}'
                $lowerFilters = (Get-ItemProperty -LiteralPath $classKey -Name 'LowerFilters' -ErrorAction SilentlyContinue).LowerFilters
                if ($null -eq $lowerFilters) {
                    New-ItemProperty -LiteralPath $classKey -Name 'LowerFilters' -Value ([string[]]@('rdyboost')) -PropertyType MultiString -Force | Out-Null
                }
                elseif (@($lowerFilters) -notcontains 'rdyboost') {
                    New-ItemProperty -LiteralPath $classKey -Name 'LowerFilters' -Value ([string[]](@($lowerFilters) + 'rdyboost')) -PropertyType MultiString -Force | Out-Null
                }

                # Enable ReadyBoost
                New-ItemProperty -LiteralPath 'HKLM:\SYSTEM\CurrentControlSet\Services\rdyboost' -Name 'Start' -Value 0 -PropertyType DWord -Force | Out-Null

                # Add the ReadyBoost tab
                New-Item -Path 'Registry::HKEY_CLASSES_ROOT\Drive\shellex\PropertySheetHandlers\{55B3A0BD-4D28-42fe-8CFB-FA3EDFF969B8}' -Force | Out-Null

                # Enable SysMain (Prefetch, Memory Management features)
                New-ItemProperty -LiteralPath 'HKLM:\SYSTEM\CurrentControlSet\Services\SysMain' -Name 'Start' -Value 2 -PropertyType DWord -Force | Out-Null
            }
        }
    }
}
