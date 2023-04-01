Write-Host Installing Scoop...
curl "https://cdn.jsdelivr.net/gh/ScoopInstaller/Install@master/install.ps1" -o "$env:temp\Scoop-Install.ps1"
PowerShell -ExecutionPolicy Bypass "$env:temp\Scoop-Install.ps1" -RunAsAdmin

Write-Host Refreshing environment for Scoop...
& refreshenv.cmd

Write-Host Installing Git...
& "$env:userprofile\scoop\shims\scoop.ps1" install git

Write-Host Adding extras and games bucket...
& "$env:userprofile\scoop\shims\scoop.ps1" bucket add extras
& "$env:userprofile\scoop\shims\scoop.ps1" bucket add games

Write-Host "`nCompleted.`n"
Pause