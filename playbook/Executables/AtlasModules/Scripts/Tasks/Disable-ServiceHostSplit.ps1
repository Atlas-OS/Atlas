$ErrorActionPreference = 'Stop'

# SvcHostSplitDisable reduces the process count on memory-rich systems. Xbox services are
# excluded because Game Bar and related services can fail when forced back into shared hosts.
Get-ChildItem -Path 'HKLM:\SYSTEM\CurrentControlSet\Services' -ErrorAction Stop |
    Where-Object { $_.PSChildName -notmatch 'Xbl|Xbox' } |
    ForEach-Object {
        $servicePath = $_.PSPath
        $serviceName = $_.PSChildName
        $service = Get-ItemProperty -Path $servicePath -ErrorAction SilentlyContinue
        if ($null -ne $service -and $null -ne $service.PSObject.Properties['Start']) {
            try {
                Set-ItemProperty -Path $servicePath -Name 'SvcHostSplitDisable' -Type DWord -Value 1 -Force -ErrorAction Stop
            }
            catch {
                if ($_.FullyQualifiedErrorId -like '*UnauthorizedAccessException*' -or $_.Exception -is [System.UnauthorizedAccessException]) {
                    Write-Warning "Skipping protected service '$serviceName': $($_.Exception.Message)"
                }
                else {
                    throw
                }
            }
        }
    }
