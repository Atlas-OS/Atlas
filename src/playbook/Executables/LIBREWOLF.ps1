$ProgressPreference = "SilentlyContinue"
$ErrorActionPreference = "Stop"

# Define variables
$updaterPath = "$env:programfiles\LibreWolf\librewolf-winupdater"
$librewolfPath = "$env:programfiles\LibreWolf"
$desktop = [Environment]::GetFolderPath("Desktop")
$startMenu = [Environment]::GetFolderPath("CommonPrograms")

# Get latest LibreWolf download link
Write-Output "Getting the latest LibreWolf download link"
$librewolfVersion = Invoke-RestMethod -Uri "https://gitlab.com/api/v4/projects/44042130/releases" | ForEach-Object { $_.name } | Select-Object -First 1
$librewolfFileName = "librewolf-$librewolfVersion-windows-x86_64-setup.exe"
$librewolfDownload = "https://gitlab.com/api/v4/projects/44042130/packages/generic/librewolf/$librewolfVersion/$librewolfFileName"

# Get latest LibreWolf-WinUpdater download link
Write-Output "Getting the latest LibreWolf-WinUpdater download link"
$librewolfUpdaterURI = "https://codeberg.org/api/v1/repos/ltguillaume/librewolf-winupdater/releases?draft=false&pre-release=false&page=1&limit=1"
$librewolfUpdaterDownload = (Invoke-RestMethod -Uri "$librewolfUpdaterURI" -Headers @{ "accept" = "application/json" }).Assets |
	Where-Object { $_.name -like "*.zip" } |
	Select-Object -ExpandProperty browser_download_url

# Output paths
$outputLibrewolf = "$env:systemdrive\$librewolfFileName"
$outputLibrewolfUpdater = "$env:systemdrive\librewolf-winupdater.zip"

# Download files
Write-Output "Downloading the latest LibreWolf setup"
Invoke-WebRequest -Uri $librewolfDownload -OutFile $outputLibrewolf
Write-Output "Downloading the latest LibreWolf WinUpdater ZIP"
Invoke-WebRequest -Uri $librewolfUpdaterDownload -OutFile $outputLibrewolfUpdater

# Install LibreWolf & LibreWolf-WinUpdater
Write-Output "Installing LibreWolf silently"
Start-Process -Wait -FilePath $outputLibrewolf -ArgumentList "/S"
if (!(Test-Path $librewolfPath)) {
	Write-Host "Installing LibreWolf silently failed."
	exit 1
}
Write-Output "Installing/extracting Librewolf-WinUpdater"
Expand-Archive -Path $outputLibrewolfUpdater -DestinationPath "$env:programfiles\LibreWolf\librewolf-winupdater" -Force

# Automatic updater
Write-Output "Adding automatic updater task"
$Title = "LibreWolf WinUpdater"
$Action   = New-ScheduledTaskAction -Execute "$updaterPath\LibreWolf-WinUpdater.exe" -Argument "/Scheduled"
$Settings = New-ScheduledTaskSettingsSet -AllowStartIfOnBatteries -DontStopIfGoingOnBatteries -RunOnlyIfNetworkAvailable
$7Hours   = New-ScheduledTaskTrigger -Once -At (Get-Date -Minute 0 -Second 0).AddHours(1) -RepetitionInterval (New-TimeSpan -Hours 7)
$AtLogon  = New-ScheduledTaskTrigger -AtLogOn
$AtLogon.Delay = 'PT1M'
$User = (Get-CimInstance -ClassName Win32_ComputerSystem | Select-Object -ExpandProperty UserName) -replace ".*\\"
Register-ScheduledTask -TaskName "$Title ($User)" -Action $Action -Settings $Settings -Trigger $7Hours,$AtLogon -User $User -RunLevel Highest -Force | Out-Null

# Shortcuts
Write-Output "Creating shortcuts"
function Add-Shortcut {
	param ( [string]$Source, [string]$Destination, [string]$WorkingDir )
	$WshShell = New-Object -comObject WScript.Shell
	$Shortcut = $WshShell.CreateShortcut($Destination)
	$Shortcut.TargetPath = $Source
	$Shortcut.WorkingDirectory = $WorkingDir
	$Shortcut.Save()
}
Add-Shortcut -Source "$librewolfPath\librewolf.exe" -Destination "$desktop\LibreWolf.lnk" -WorkingDir $librewolfPath
Add-Shortcut -Source "$updaterPath\Librewolf-WinUpdater.exe" -Destination "$startMenu\LibreWolf\LibreWolf WinUpdater.lnk" -WorkingDir $librewolfPath

# Temp files
Write-Output "Removing temporary installer files"
Remove-Item "$outputLibrewolf" -Force
Remove-Item "$outputLibrewolfUpdater" -Force