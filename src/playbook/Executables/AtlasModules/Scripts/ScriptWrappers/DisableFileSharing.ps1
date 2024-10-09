#Requires -RunAsAdministrator

param (
    [switch]$Silent
)

$fileSharingConfigPath = "$([Environment]::GetFolderPath('Windows'))\AtlasDesktop\3. General Configuration\File Sharing"

# Disable network items
Disable-NetAdapterBinding -Name "*" -ComponentID ms_msclient, ms_server, ms_lltdio, ms_rspndr | Out-Null

# Disable NetBios over TCP/IP
$interfaces = Get-ChildItem "HKLM:\SYSTEM\CurrentControlSet\Services\NetBT\Parameters\Interfaces" -Recurse | Where-Object { $_.GetValue("NetbiosOptions") -ne $null }
foreach ($interface in $interfaces) {
    Set-ItemProperty -Path $interface.PSPath -Name "NetbiosOptions" -Value 2 | Out-Null
}

# Disable NetBIOS service
sc.exe config NetBT start=disabled | Out-Null

# Set network profile to 'Public Network'
Get-NetConnectionProfile | Set-NetConnectionProfile -NetworkCategory Public
$profiles = Get-ChildItem "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\NetworkList\Profiles" -Recurse | Where-Object { $_.GetValue("Category") -ne $null }
foreach ($profile in $profiles) {
    Set-ItemProperty -Path $profile.PSPath -Name "Category" -Value 0 | Out-Null
}

# Disable network discovery firewall rules
Get-NetFirewallRule | Where-Object {
    # File and Printer Sharing, Network Discovery
    ($_.Group -eq "@FirewallAPI.dll,-28502" -or $_.Group -eq "@FirewallAPI.dll,-32752") -or
    ($_.DisplayGroup -eq "File and Printer Sharing" -or $_.DisplayGroup -eq "Network Discovery") -and
    $_.Profile -like "*Private*"
} | Disable-NetFirewallRule

reg import "$fileSharingConfigPath\Network Navigation Pane\Disable Network Navigation Pane (default).reg" | Out-Null
reg import "$fileSharingConfigPath\Give Access To Menu\Disable Give Access To Menu (default).reg" | Out-Null

if ($Silent) { exit }

Write-Host "`nCompleted! " -ForegroundColor Green -NoNewLine
Write-Host "You'll need to restart to apply the changes." -ForegroundColor Yellow
$null = Read-Host "Press Enter to exit..."
exit