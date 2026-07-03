.\AtlasModules\initPowerShell.ps1

function Get-ProfilePathFromSid {
    param (
        [Parameter(Mandatory = $true)]
        [string]$Sid
    )

    $profileListPath = "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\ProfileList\$Sid"
    $profilePath = (Get-ItemProperty -Path $profileListPath -Name ProfileImagePath -ErrorAction SilentlyContinue).ProfileImagePath
    if ([string]::IsNullOrEmpty($profilePath)) {
        return $null
    }

    return [Environment]::ExpandEnvironmentVariables($profilePath)
}

foreach ($userKey in (Get-RegUserPaths).PsPath) {
    $default = if ($userKey -match 'AME_UserHive_Default') { $true }
    $sid = Split-Path $userKey -Leaf

    # Get Local AppData
    $appData = if ($default) {
        Get-UserPath -Folder 'F1B32785-6FBA-4FCF-9D55-7B8E7F157091'
    } else {
        (Get-ItemProperty "$userKey\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\Shell Folders" -Name 'Local AppData' -EA 0).'Local AppData'
    }

    if (!$default -and ([string]::IsNullOrEmpty($appData) -or !(Test-Path $appData -PathType Container))) {
        $profilePath = Get-ProfilePathFromSid -Sid $sid
        if (![string]::IsNullOrEmpty($profilePath)) {
            $appData = Join-Path $profilePath 'AppData\Local'
        }
    }
    
    Write-Title "Configuring Start Menu for '$sid'..."
    if ([string]::IsNullOrEmpty($appData) -or !(Test-Path $appData -PathType Container)) {
        Write-Warning "Couldn't find Local AppData path for $sid; skipping Start Menu file cleanup."
    } else {
        Write-Output "Copying default layout XML"
        Copy-Item -Path "Layout.xml" -Destination "$appdata\Microsoft\Windows\Shell\LayoutModification.xml" -Force
        
        if (!$default) {
            Write-Output "Clearing Start Menu pinned items"

            $packages = Get-ChildItem -Path "$appdata\Packages" -Directory | Where-Object { $_.Name -match "Microsoft.Windows.StartMenuExperienceHost" }
            foreach ($package in $packages) {
                $bins = Get-ChildItem -Path "$appdata\Packages\$($package.Name)\LocalState" -File | Where-Object { $_.Name -like "start*.bin" }
                foreach ($bin in $bins.FullName) {
                    Remove-Item -Path $bin -Force
                }
            }
        }
    }
    
    if (!$default) {
        Write-Output "Clearing default 'tilegrid'"
        $tilegrid = Get-ChildItem -Path "$userKey\SOFTWARE\Microsoft\Windows\CurrentVersion\CloudStore\Store\Cache\DefaultAccount" -Recurse | Where-Object { $_.Name -match "start.tilegrid" }    
        foreach ($key in $tilegrid) {
            Remove-Item -Path $key.PSPath -Force
        }
    }

    Write-Output "Removing advertisements/stubs from Start Menu (23H2+)"
    Remove-ItemProperty -Path "$userKey\SOFTWARE\Microsoft\Windows\CurrentVersion\Start" -Name 'Config' -Force -EA 0
}
