# Add Music & Videos to Home (Fix missing folders in Quick Access)
function Add-MusicVideosToHome {
    $o = New-Object -ComObject shell.application
    $currentPins = $o.Namespace('shell:::{679f85cb-0220-4080-b29b-5540cc05aab6}').Items() | ForEach-Object { $_.Path }
    
    foreach ($path in @(
        [Environment]::GetFolderPath('MyVideos'),
        [Environment]::GetFolderPath('MyMusic')
    )) {
        if ($currentPins -notcontains $path) {
            $o.Namespace($path).Self.InvokeVerb('pintohome')
        }
    }
}



# Configure Time Servers for better accuracy
function Set-TimeServers {
    Start-Service -Name "w32time" -ErrorAction SilentlyContinue
    w32tm /config /syncfromflags:manual /manualpeerlist:"0.pool.ntp.org 1.pool.ntp.org 2.pool.ntp.org 3.pool.ntp.org"
    w32tm /config /update
    w32tm /resync
}

# Rebuild Performance Counters
function Reset-PerformanceCounters {
    lodctr /r
    lodctr /r
    winmgmt /resyncperf
}

function Invoke-AllMiscSystemUtilities {
    Write-Host "Add-MusicVideosToHome"
    Add-MusicVideosToHome
    Write-Host "set time servers"
    Set-TimeServers
    Write-Host "Resetting performance counter"
    Reset-PerformanceCounters
}

Export-ModuleMember -Function Invoke-AllMiscSystemUtilities
