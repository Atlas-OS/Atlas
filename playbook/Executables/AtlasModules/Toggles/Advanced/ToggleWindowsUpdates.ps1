function Get-AtlasWindowsUpdateTaskPaths {
    return @(
        'Microsoft\Windows\WindowsUpdate\sih'
        'Microsoft\Windows\WindowsUpdate\sihboot'
        'Microsoft\Windows\UpdateOrchestrator\Schedule Scan'
        'Microsoft\Windows\UpdateOrchestrator\USO_UxBroker'
        'Microsoft\Windows\UpdateOrchestrator\Reboot'
    )
}

function Set-AtlasWindowsUpdateTaskState {
    param(
        [Parameter(Mandatory = $true)]
        [bool]$Enabled
    )

    # The UpdateOrchestrator tasks refuse changes from Administrators and accept
    # SYSTEM, which is why this toggle runs as TrustedInstaller.
    Import-Module -Name ScheduledTasks -ErrorAction Stop
    $allTasks = @(Get-ScheduledTask -ErrorAction Stop)
    foreach ($taskPath in (Get-AtlasWindowsUpdateTaskPaths)) {
        $task = $allTasks | Where-Object {
            ([string]::Concat([string]$_.TaskPath, [string]$_.TaskName)).Trim([char]'\') -ieq $taskPath
        } | Select-Object -First 1
        if ($null -eq $task) {
            Write-Verbose "ToggleWindowsUpdates: optional scheduled task '$taskPath' is not present on this Windows build."
            continue
        }

        if ($Enabled) {
            Enable-ScheduledTask -InputObject $task -ErrorAction Stop | Out-Null
        }
        else {
            Disable-ScheduledTask -InputObject $task -ErrorAction Stop | Out-Null
        }
    }
}

function Disable-AtlasWindowsUpdates {
    param($Toggle)

    [void]$Toggle
    foreach ($serviceName in @('wuauserv', 'UsoSvc', 'WaaSMedicSvc')) {
        $service = Get-Service -Name $serviceName -ErrorAction Stop
        if ($service.Status -ne [System.ServiceProcess.ServiceControllerStatus]::Stopped) {
            Stop-Service -Name $serviceName -Force -ErrorAction Stop
        }
        Set-AtlasServiceStartup -Name $serviceName -StartupType 4
    }
    Set-AtlasWindowsUpdateTaskState -Enabled $false

    $wu = 'HKLM:\SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate'
    Set-AtlasRegistryValue -Path $wu -Name 'DisableWindowsUpdateAccess' -Type DWord -Data 1
    Set-AtlasRegistryValue -Path $wu -Name 'DoNotConnectToWindowsUpdateInternetLocations' -Type DWord -Data 1
    Set-AtlasRegistryValue -Path "$wu\AU" -Name 'NoAutoUpdate' -Type DWord -Data 1

    Import-AtlasModule -Name Atlas.Shell
    Set-AtlasSettingsPageVisibility -Operation hide -Page windowsupdate
}

function Enable-AtlasWindowsUpdates {
    param($Toggle)

    [void]$Toggle
    # Lift the blocking policies first, so a failure later in the run can't leave
    # updates blocked, and the services start without them.
    $wu = 'HKLM:\SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate'
    Remove-AtlasRegistryValue -Path $wu -Name 'DisableWindowsUpdateAccess'
    Remove-AtlasRegistryValue -Path $wu -Name 'DoNotConnectToWindowsUpdateInternetLocations'
    Remove-AtlasRegistryValue -Path "$wu\AU" -Name 'NoAutoUpdate'

    Import-AtlasModule -Name Atlas.Shell
    Set-AtlasSettingsPageVisibility -Operation unhide -Page windowsupdate

    foreach ($serviceName in @('wuauserv', 'UsoSvc', 'WaaSMedicSvc')) {
        Set-AtlasServiceStartup -Name $serviceName -StartupType 3
        $service = Get-Service -Name $serviceName -ErrorAction Stop
        if ($service.Status -eq [System.ServiceProcess.ServiceControllerStatus]::Stopped) {
            Start-Service -Name $serviceName -ErrorAction Stop
        }
    }
    Set-AtlasWindowsUpdateTaskState -Enabled $true
}
