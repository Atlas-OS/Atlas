$scriptPath = "AtlasDesktop\8. Troubleshooting\Network\Reset Network to Atlas Default.cmd"

Start-Process -FilePath $scriptPath -ArgumentList "/silent" -NoNewWindow -Wait

Write-Host "Atlas' optimized network settings have been applied successfully."
