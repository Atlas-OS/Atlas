# Atlas.Software domain: OneDrive removal.
#
# Faithful port of Executables\ONED.cmd. Everything is best-effort (the batch silenced
# every command), because most of these leftovers only exist in some configurations.
# The actual OneDrive setup in Windows is stripped at a component level in the
# miscellaneous CBS package; this removes the preinstalled client and its leftovers.

function Remove-AtlasOneDriveItem {
    param([Parameter(Mandatory = $true)][string[]]$Path)

    foreach ($item in $Path) {
        Remove-Item -LiteralPath $item -Recurse -Force -ErrorAction SilentlyContinue
    }
}

function Clear-AtlasOneDriveUserRegistry {
    param(
        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [string]$Sid
    )

    Write-Host "Making changes for '$Sid'..."
    $root = "Registry::HKEY_USERS\$Sid"

    # Delete OneDrive keys under these per-user parents
    foreach ($parent in @(
        'SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\BannerStore'
        'SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\AutoplayHandlers\Handlers'
        'SOFTWARE\Microsoft\Windows\CurrentVersion\App Paths'
        'SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall'
    )) {
        foreach ($key in @(Get-ChildItem -Path "$root\$parent" -ErrorAction SilentlyContinue)) {
            if ($key.Name -like '*OneDrive*') {
                Remove-Item -LiteralPath "Registry::$($key.Name)" -Recurse -Force -ErrorAction SilentlyContinue
            }
        }
    }

    Remove-AtlasOneDriveItem -Path @(
        "$root\SOFTWARE\Classes\CLSID\{018D5C66-4533-4307-9B53-224DE2ED1FE6}"
        "$root\SOFTWARE\Classes\WOW6432Node\CLSID\{018D5C66-4533-4307-9B53-224DE2ED1FE6}"
        "$root\SOFTWARE\Classes\CLSID\{A0A7DEC5-B1A7-4A47-847D-1D005787621E}"
        "$root\SOFTWARE\Classes\WOW6432Node\CLSID\{A0A7DEC5-B1A7-4A47-847D-1D005787621E}"
        "$root\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\Desktop\NameSpace\{018D5C66-4533-4307-9B53-224DE2ED1FE6}"
        "$root\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\Desktop\NameSpace\{A0A7DEC5-B1A7-4A47-847D-1D005787621E}"
    )

    Remove-ItemProperty -Path "$root\Environment" -Name 'OneDrive' -Force -ErrorAction SilentlyContinue
    Remove-ItemProperty -Path "$root\SOFTWARE\Microsoft\Windows\CurrentVersion\Run" -Name 'OneDriveSetup' -Force -ErrorAction SilentlyContinue

    # Fix folder redirection - this sometimes persists after uninstallation
    $shellFolders = "$root\Software\Microsoft\Windows\CurrentVersion\Explorer\User Shell Folders"
    foreach ($entry in @(
        @{ Name = '{F42EE2D3-909F-4907-8871-4C22FC0BF756}'; Data = '%USERPROFILE%\Documents' }
        @{ Name = 'Personal'; Data = '%USERPROFILE%\Documents' }
        @{ Name = 'Desktop'; Data = '%USERPROFILE%\Desktop' }
        @{ Name = 'My Pictures'; Data = '%USERPROFILE%\Pictures' }
        @{ Name = '{0DDD015D-B06C-45D5-8C4C-F59713854639}'; Data = '%USERPROFILE%\Pictures' }
    )) {
        try {
            New-ItemProperty -Path $shellFolders -Name $entry.Name -Value $entry.Data -PropertyType ExpandString -Force -ErrorAction Stop | Out-Null
        }
        catch {
            Write-AtlasLog -Level Warning -Message "Couldn't fix the '$($entry.Name)' shell folder for '$Sid': $($_.Exception.Message)"
        }
    }
}

function Remove-AtlasOneDrive {
    <#
    .SYNOPSIS
        Uninstalls the preinstalled OneDrive client and cleans up its per-user
        registry entries, folders, scheduled tasks and shell extensions.
    #>
    Stop-Process -Name 'OneDrive' -Force -ErrorAction SilentlyContinue

    $windir = [Environment]::GetFolderPath('Windows')
    $setupPaths = @(
        (Join-Path -Path $windir -ChildPath 'System32\OneDriveSetup.exe')
        (Join-Path -Path $windir -ChildPath 'SysWOW64\OneDriveSetup.exe')
    )

    $setupFound = $false
    foreach ($setupPath in $setupPaths) {
        if (Test-Path -LiteralPath $setupPath -PathType Leaf) {
            $setupFound = $true
            try {
                Start-Process -FilePath $setupPath -ArgumentList '/uninstall' -Wait -WindowStyle Hidden
            }
            catch {
                Write-AtlasLog -Level Warning -Message "Running '$setupPath /uninstall' failed: $($_.Exception.Message)"
            }
        }
    }

    # Try WinGet as a fallback in case the OneDrive setup files can't be found
    if (-not $setupFound) {
        try {
            & winget uninstall --id 'Microsoft.OneDrive' --silent --accept-source-agreements *> $null
            & winget uninstall 'Microsoft OneDrive' --silent --accept-source-agreements *> $null
        }
        catch {
            Write-AtlasLog -Level Warning -Message "WinGet OneDrive uninstall fallback failed: $($_.Exception.Message)"
        }
    }

    # Per-user registry cleanup. A 'Volatile Environment' key marks a proper user
    # profile (built-in accounts/SIDs don't have it); AME_UserHive_* is the default
    # user hive loaded by the installer.
    foreach ($hive in @(Get-ChildItem -Path 'Registry::HKEY_USERS' -ErrorAction SilentlyContinue)) {
        $sid = $hive.PSChildName
        $isUser = ($sid -like 'S-*') -and (Test-Path -LiteralPath "Registry::HKEY_USERS\$sid\Volatile Environment")
        $isDefaultHive = $sid -match '^AME_UserHive_[^_]+$'
        if ($isUser -or $isDefaultHive) {
            Clear-AtlasOneDriveUserRegistry -Sid $sid
        }
    }

    Remove-AtlasOneDriveItem -Path @(
        (Join-Path -Path $env:ProgramData -ChildPath 'Microsoft OneDrive')
        (Join-Path -Path $env:LOCALAPPDATA -ChildPath 'Microsoft\OneDrive')
        (Join-Path -Path $env:SystemDrive -ChildPath 'OneDriveTemp')
    )

    foreach ($userProfile in @(Get-ChildItem -Path (Join-Path -Path $env:SystemDrive -ChildPath 'Users') -Directory -ErrorAction SilentlyContinue)) {
        Remove-AtlasOneDriveItem -Path @(
            (Join-Path -Path $userProfile.FullName -ChildPath 'AppData\Local\Microsoft\OneDrive')
            (Join-Path -Path $userProfile.FullName -ChildPath 'OneDrive')
            (Join-Path -Path $userProfile.FullName -ChildPath 'AppData\Roaming\Microsoft\Windows\Start Menu\Programs\OneDrive.lnk')
        )
    }

    foreach ($key in @(Get-ChildItem -Path 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\SyncRootManager' -ErrorAction SilentlyContinue)) {
        if ($key.Name -like '*OneDrive*') {
            Remove-Item -LiteralPath "Registry::$($key.Name)" -Recurse -Force -ErrorAction SilentlyContinue
        }
    }

    foreach ($taskPattern in @('OneDrive Reporting Task*', 'OneDrive Standalone Update Task*')) {
        foreach ($task in @(Get-ScheduledTask -TaskName $taskPattern -ErrorAction SilentlyContinue)) {
            try {
                Unregister-ScheduledTask -InputObject $task -Confirm:$false -ErrorAction Stop
            }
            catch {
                Write-AtlasLog -Level Warning -Message "Couldn't delete scheduled task '$($task.TaskName)': $($_.Exception.Message)"
            }
        }
    }

    Remove-AtlasOneDriveItem -Path @(
        'HKLM:\SOFTWARE\Classes\CLSID\{018D5C66-4533-4307-9B53-224DE2ED1FE6}'
        'HKLM:\SOFTWARE\Classes\WOW6432Node\CLSID\{018D5C66-4533-4307-9B53-224DE2ED1FE6}'
        'HKLM:\SOFTWARE\Classes\CLSID\{A0A7DEC5-B1A7-4A47-847D-1D005787621E}'
        'HKLM:\SOFTWARE\Classes\WOW6432Node\CLSID\{A0A7DEC5-B1A7-4A47-847D-1D005787621E}'
    )
}
