$env:PSModulePath += ";$PWD\AtlasModules\Scripts\Modules"
$ProgressPreference = "SilentlyContinue"
$ErrorActionPreference = "Stop"

# Initial variables
$drive = Get-SystemDrive
$desktop = [Environment]::GetFolderPath("Desktop")
$startMenu = [Environment]::GetFolderPath("CommonPrograms")
$programs = [Environment]::GetFolderPath("ProgramFiles")
$updaterPath = "$programs\LibreWolf\librewolf-winupdater"
$librewolfPath = "$programs\LibreWolf"

Write-Output "Getting the latest LibreWolf download link"
$gitLabId = '44042130'
$librewolfVersion = (Invoke-RestMethod "https://gitlab.com/api/v4/projects/$gitLabId/releases")[0].Name
if ([string]::IsNullOrEmpty($librewolfVersion)) {
	throw "GitLab API returned nothing!"
}
$librewolfFileName = "librewolf-$librewolfVersion-windows-x86_64-setup.exe"
$librewolfDownload = "https://gitlab.com/api/v4/projects/$gitLabId/packages/generic/librewolf/$librewolfVersion/$librewolfFileName"

Write-Output "Downloading the latest LibreWolf setup"
$outputLibrewolf = "$drive\$librewolfFileName"
curl.exe -LSs "$librewolfDownload" -o "$outputLibrewolf"

Write-Output "Installing LibreWolf silently"
Start-Process -Wait -FilePath $outputLibrewolf -ArgumentList "/S"
if (!(Test-Path $librewolfPath)) {
	throw "Installing LibreWolf silently failed."
}

Write-Output "Creating LibreWolf Desktop shortcut"
New-Shortcut -Source "$librewolfPath\librewolf.exe" -Destination "$desktop\LibreWolf.lnk" -WorkingDir $librewolfPath


Write-Title "Installing LibreWolf-WinUpdater..."
Write-Output "Getting the latest LibreWolf-WinUpdater download link"
$librewolfUpdaterURI = "https://codeberg.org/api/v1/repos/ltguillaume/librewolf-winupdater/releases?draft=false&pre-release=false&page=1&limit=1"
$librewolfUpdaterDownload = (Invoke-RestMethod -Uri "$librewolfUpdaterURI").Assets |
	Where-Object { $_.name -like "*.zip" } |
	Select-Object -ExpandProperty browser_download_url

Write-Output "Downloading the latest LibreWolf WinUpdater ZIP"
$outputLibrewolfUpdater = "$drive\librewolf-winupdater.zip"
curl.exe -LSs "$librewolfUpdaterDownload" -o "$outputLibrewolfUpdater"

Write-Output "Extracting Librewolf-WinUpdater"
Expand-Archive -Path $outputLibrewolfUpdater -DestinationPath "$programs\LibreWolf\librewolf-winupdater" -Force

Write-Output "Adding automatic updater task"
foreach ($User in (Get-CimInstance -ClassName Win32_UserAccount -Filter "Disabled=False").Name) {
	$Action   = New-ScheduledTaskAction -Execute "$updaterPath\LibreWolf-WinUpdater.exe" -Argument "/Scheduled"
	$Settings = New-ScheduledTaskSettingsSet -AllowStartIfOnBatteries -DontStopIfGoingOnBatteries -RunOnlyIfNetworkAvailable
	$7Hours   = New-ScheduledTaskTrigger -Once -At (Get-Date -Minute 0 -Second 0).AddHours(1) -RepetitionInterval (New-TimeSpan -Hours 7)
	$AtLogon  = New-ScheduledTaskTrigger -AtLogOn
	$AtLogon.Delay = 'PT1M'
	Register-ScheduledTask -TaskName "LibreWolf WinUpdater ($User)" -Action $Action -Settings $Settings -Trigger $7Hours,$AtLogon -User $User -RunLevel Highest -Force | Out-Null	
}

Write-Output "Adding LibreWolf WinUpdater shortcut"
New-Shortcut -Source "$updaterPath\Librewolf-WinUpdater.exe" -Destination "$startMenu\LibreWolf\LibreWolf WinUpdater.lnk" -WorkingDir $librewolfPath

# Finish
Write-Title "Removing temp files"
Remove-Item "$outputLibrewolf" -Force
Remove-Item "$outputLibrewolfUpdater" -Force