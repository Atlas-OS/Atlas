$windir = [Environment]::GetFolderPath('Windows')

# SSD specific settings
if ((Get-Partition | Where-Object { $_.IsBoot } | Get-Disk | Get-PhysicalDisk).MediaType -eq "SSD") {
    # Remove lower filters for rdyboost driver
    $regPath = "HKLM:\SYSTEM\CurrentControlSet\Control\Class\{71a27cdd-812a-11d0-bec7-08002be2092f}"
    $val = (Get-ItemProperty -Path $regPath -Name "LowerFilters")."LowerFilters" | Where-Object { $_ -ne 'rdyboost' }
    Set-ItemProperty -Path $regPath -Name "LowerFilters" -Value $val -Force

    # Disable ReadyBoost
    Set-Service -Name rdyboost -StartupType Disabled
    # Remove ReadyBoost tab
    Remove-Item -Path "Registry::HKCR\Drive\shellex\PropertySheetHandlers\{55B3A0BD-4D28-42fe-8CFB-FA3EDFF969B8}" -Force -ErrorAction SilentlyContinue

    # Disable SysMain - contains Superfetch, Prefetch, Memory Management Agents
    Set-Service -Name SysMain -StartupType Disabled
}

# Disable brightness slider service if it's not supported on the current display
$startup = 'Automatic'
try {
    Get-WmiObject -Namespace root/WMI -Class WmiMonitorBrightnessMethods -ErrorAction Stop | Out-Null
} catch {
    if ((Get-ComputerInfo).CsPCSystemType -eq 'Desktop') {
        $startup = 'Disabled'
    }
}
Set-Service -Name DisplayEnhancementService -StartupType $startup