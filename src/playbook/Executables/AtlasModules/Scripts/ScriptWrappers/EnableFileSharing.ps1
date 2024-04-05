#Requires -RunAsAdministrator

$networkDiscoveryConfigPath = "$([Environment]::GetFolderPath('Windows'))\AtlasDesktop\3. General Configuration\Network Discovery"

# Enable network items
Enable-NetAdapterBinding -Name "*" -ComponentID ms_msclient, ms_server, ms_lltdio, ms_rspndr | Out-Null

# Enable Network Discovery services and its dependencies
Start-Process -FilePath "$networkDiscoveryConfigPath\Enable Network Discovery Services (default)" -ArgumentList "/silent" -WindowStyle Hidden

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
    $profiles = Get-ChildItem "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\NetworkList\Profiles" -Recurse | Where-Object { $_.GetValue("Category") -ne $null }
    foreach ($profile in $profiles) {
        Set-ItemProperty -Path $profile.PSPath -Name "Category" -Value 1 | Out-Null
    }

    # Enable network discovery firewall rules
    Get-NetFirewallRule | Where-Object { 
        ($_.DisplayGroup -eq "File and Printer Sharing" -or $_.DisplayGroup -eq "Network Discovery") -and
        $_.Profile -like "*Private*"
    } | Enable-NetFirewallRule

    # Set up network connected devices automatically
    New-Item -Path "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\NcdAutoSetup\Private" -Force -EA SilentlyContinue | Out-Null
    Set-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\NcdAutoSetup\Private" -Name "AutoSetup" -Value 1 | Out-Null
}

choice /c:yn /n /m "Would you like to add the Network Navigation Pane to the Explorer sidebar? [Y/N] "
if ($LASTEXITCODE -eq 1) {
    reg import "$networkDiscoveryConfigPath\Network Navigation Pane\User Network Navigation Pane choice.reg" | Out-Null
}

Write-Host "Completed!" -ForegroundColor Green
Write-Host "Press any key to exit... " -NoNewLine
$Host.UI.RawUI.ReadKey('NoEcho,IncludeKeyDown') | Out-Null
exit