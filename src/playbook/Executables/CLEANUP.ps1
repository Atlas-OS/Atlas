.\AtlarModules\initPowerShell.ps1
function Invoke-AtlarDiskCleanup {
	# Kill running cleanmgr instances, as they will prevent new cleanmgr from starting
	Get-Process -Name cleanmgr -EA 0 | Stop-Process -Force -EA 0
	# Disk Cleanup preset
	# 2 = enabled
	# 0 = disabled
	$baseKey = 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\VolumeCaches'
	$regValues = @{
		"Active Setup Temp Folders" = 2
		"BranchCache" = 2
		"D3D Shader Cache" = 0
		"Delivery Optimization Files" = 2
		"Diagnostic Data Viewer database files" = 2
		"Downloaded Program Files" = 2
		"Internet Cache Files" = 2
		"Language Pack" = 0
		"Old ChkDsk Files" = 2
		"Recycle Bin" = 0
		"RetailDemo Offline Content" = 2
		"Setup Log Files" = 2
		"System error memory dump files" = 2
		"System error minidump files" = 2
		"Temporary Files" = 0
		"Thumbnail Cache" = 2
		"Update Cleanup" = 0
		"User file versions" = 2
		"Windows Error Reporting Files" = 2
		"Windows Defender" = 2
		"Temporary Sync Files" = 2
		"Device Driver Packages" = 2
	}
	foreach ($entry in $regValues.GetEnumerator()) {
		$key = "$baseKey\$($entry.Key)"

		if (!(Test-Path $key)) {
			Write-Output "'$key' not found, not configuring it."
		} else {
			Set-ItemProperty -Path "$baseKey\$($entry.Key)" -Name 'StateFlags0064' -Value $entry.Value -Type DWORD
		}
	}

	# Run preset 64 (0-65535)
	# As cleanmgr has multiple processes, there's no point in making the window hidden as it won't apply
	Start-Process -FilePath "cleanmgr.exe" -ArgumentList "/sagerun:64" 2>&1 | Out-Null
}

# Check for other installations of Windows
# If so, don't cleanup as it will also cleanup other drives, which will be slow, and we don't want to touch other data
$noCleanmgr = $false
$drives = (Get-PSDrive -PSProvider FileSystem).Root | Where-Object { $_ -notmatch $(Get-SystemDrive) }
foreach ($drive in $drives) {
	if (Test-Path -Path $(Join-Path -Path $drive -ChildPath 'Windows') -PathType Container) {
		Write-Output "Not running Disk Cleanup, other Windows drives found."
		$noCleanmgr = $true
		break
	}
}

if (!$noCleanmgr) {
	Write-Output "No other Windows drives found, running Disk Cleanup."
	Invoke-AtlarDiskCleanup
}

# Clear the user temp folder
foreach ($path in @($env:temp, $env:tmp, "$env:localappdata\Temp")) {
	if (Test-Path $path -PathType Container) {
		$userTemp = $path
		break
	}
}
if ($path) {
	Write-Output "Cleaning user TEMP folder..."
	Get-ChildItem -Path $userTemp | Where-Object { $_.Name -ne 'AME' } | Remove-Item -Force -Recurse -EA 0
} else {
	Write-Error "User temp folder not found!"
}

# Clear the system temp folder
$machine = [System.EnvironmentVariableTarget]::Machine
foreach ($path in @(
	[System.Environment]::GetEnvironmentVariable("Temp", $machine),
	[System.Environment]::GetEnvironmentVariable("Tmp", $machine),
	"$([Environment]::GetFolderPath('Windows'))\Temp"
)) {
	if (Test-Path $path -PathType Container) {
		$sysTemp = $path
		break
	}
}
if ($sysTemp) {
	Write-Output "Cleaning system TEMP folder..."
	Remove-Item -Path "$sysTemp\*" -Force -Recurse -EA 0
} else {
	Write-Error "System temp folder not found!"
}

# Delete all system restore points
# This is so that users can't attempt to revert from Atlar to stock with Restore Points
# It won't work, a full Windows reinstall is required ^
vssadmin delete shadows /all /quiet