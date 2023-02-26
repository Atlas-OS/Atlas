Write-Host Installing Chocolatey...
curl "https://community.chocolatey.org/install.ps1" -o C:\Windows\AtlasModules\install.ps1
install.ps1

Write-Host Refreshing environment for Chocolatey...
& refreshenv.cmd

Write-Host Enabling global confirmation for Chocolatey
choco feature enable -n allowGlobalConfirmation

Clear-Host
Write-Host Done
Start-Sleep -Seconds 2