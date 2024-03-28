#Requires -RunAsAdministrator

param (
    [switch]$Silent
)

$networkDiscoveryConfigPath = "$([Environment]::GetFolderPath('Windows'))\AtlasDesktop\3. General Configuration\Network Discovery"

# Disable network items
Disable-NetAdapterBinding -Name "*" -ComponentID ms_msclient, ms_server, ms_lltdio, ms_rspndr | Out-Null

# Disable NetBios over TCP/IP
$interfaces = Get-ChildItem "HKLM:\SYSTEM\CurrentControlSet\Services\NetBT\Parameters\Interfaces" -Recurse | Where-Object { $_.GetValue("NetbiosOptions") -ne $null }
foreach ($interface in $interfaces) {
    Set-ItemProperty -Path $interface.PSPath -Name "NetbiosOptions" -Value 2 | Out-Null
}

# Disable NetBIOS service
setSvc.cmd NetBT 4 | Out-Null

# Set network profile to 'Public Network'
$profiles = Get-ChildItem "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\NetworkList\Profiles" -Recurse | Where-Object { $_.GetValue("Category") -ne $null }
foreach ($profile in $profiles) {
    Set-ItemProperty -Path $profile.PSPath -Name "Category" -Value 0 | Out-Null
}

# Disable network discovery firewall rules
Get-NetFirewallRule | Where-Object { 
    ($_.DisplayGroup -eq "File and Printer Sharing" -or $_.DisplayGroup -eq "Network Discovery") -and
    $_.Profile -like "*Private*"
} | Disable-NetFirewallRule

reg import "$networkDiscoveryConfigPath\Network Navigation Pane\Disable Network Navigation Pane (default).reg" | Out-Null

if ($Silent) { exit }

Clear-Host
Write-Host "Completed!" -ForegroundColor Green
Write-Host "Press any key to exit... " -NoNewLine
$Host.UI.RawUI.ReadKey('NoEcho,IncludeKeyDown') | Out-Null
exit