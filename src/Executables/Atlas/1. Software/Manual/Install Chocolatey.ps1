$isAdmin = ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)

if (-not $isAdmin) {
    $argString = ""
    if ($args) {
        $argString = $args | ForEach-Object { '"' + $_ + '"' } | Join-String ' '
    }
    Start-Process powershell.exe "-File `"$PSCommandPath`" $argString" -Verb RunAs
    exit
}

Write-Host Installing Chocolatey...
curl "https://community.chocolatey.org/install.ps1" -o C:\Windows\AtlasModules\Scripts\Chocolatey-Install.ps1
PowerShell -ExecutionPolicy Bypass Chocolatey-Install.ps1

Write-Host Refreshing environment for Chocolatey...
& refreshenv.cmd

Write-Host Enabling global confirmation for Chocolatey
choco feature enable -n allowGlobalConfirmation

Clear-Host
Write-Host Done
Start-Sleep -Seconds 2