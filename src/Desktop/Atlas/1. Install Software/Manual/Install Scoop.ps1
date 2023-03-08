Write-Host Installing Scoop...
curl "https://cdn.jsdelivr.net/gh/ScoopInstaller/Install@master/install.ps1" -o C:\Windows\AtlasModules\install.ps1
install.ps1 -RunAsAdmin

Write-Host Refreshing environment for Scoop...
& refreshenv.cmd

Write-Host Installing git...
scoop install git -g

Write-Host Adding extras and games bucket...
scoop bucket add extras
scoop bucket add games

Clear-Host
Write-Host Done
Start-Sleep -Seconds 2