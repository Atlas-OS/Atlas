#Requires -RunAsAdministrator

$networkDiscoveryConfigPath = "$([Environment]::GetFolderPath('Windows'))\AtlasDesktop\6. Advanced Configuration\Services\Network Discovery"

# Enable network items
Enable-NetAdapterBinding -Name "*" -ComponentID ms_msclient, ms_server, ms_lltdio, ms_rspndr | Out-Null

# Enable Network Discovery services and its dependencies
Start-Process -FilePath "$networkDiscoveryConfigPath\Enable Network Discovery Services (default).cmd" -ArgumentList "/silent" -WindowStyle Hidden

# Enable NetBios over TCP/IP
$interfaces = Get-ChildItem "HKLM:\SYSTEM\CurrentControlSet\Services\NetBT\Parameters\Interfaces" -Recurse | Where-Object { $_.GetValue("NetbiosOptions") -ne $null }
foreach ($interface in $interfaces) {
    Set-ItemProperty -Path $interface.PSPath -Name "NetbiosOptions" -Value 2 | Out-Null
}

# Enable NetBIOS service
sc.exe config NetBT start=system | Out-Null

choice /c:yn /n /m "Would you like to change your network profile to 'Private'? [Y/N] "
if ($LASTEXITCODE -eq 1) {
    # Set network profile to 'Private Network'
    Get-NetConnectionProfile | Set-NetConnectionProfile -NetworkCategory Private

    # Disable network discovery firewall rules
    Get-NetFirewallRule | Where-Object {
        # File and Printer Sharing, Network Discovery
        ($_.Group -eq "@FirewallAPI.dll,-28502" -or $_.Group -eq "@FirewallAPI.dll,-32752") -or
        ($_.DisplayGroup -eq "File and Printer Sharing" -or $_.DisplayGroup -eq "Network Discovery") -and
        $_.Profile -like "*Private*"
    } | Enable-NetFirewallRule

    # Set up network connected devices automatically
    New-Item -Path "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\NcdAutoSetup\Private" -Force -EA SilentlyContinue | Out-Null
    Set-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\NcdAutoSetup\Private" -Name "AutoSetup" -Value 1 | Out-Null
}

choice /c:yn /n /m "Would you like to add the Network Navigation Pane to the Explorer sidebar? [Y/N] "
if ($LASTEXITCODE -eq 1) {
    reg import "$([Environment]::GetFolderPath('Windows'))\AtlasDesktop\3. General Configuration\File Sharing\Network Navigation Pane\User Network Navigation Pane choice.reg" | Out-Null
}

choice /c:yn /n /m "Would you like to restore the 'Give access to' context menu in Explorer? [Y/N] "
if ($LASTEXITCODE -eq 1) {
    reg import "$([Environment]::GetFolderPath('Windows'))\AtlasDesktop\3. General Configuration\File Sharing\Give Access To Menu\Enable Give Access To Menu.reg" | Out-Null
}

Write-Host "`nCompleted! " -ForegroundColor Green -NoNewLine
Write-Host "You'll need to restart to apply the changes." -ForegroundColor Yellow
$null = Read-Host "Press Enter to exit..."
exit