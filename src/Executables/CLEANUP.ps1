# Clearing the user's temporary folder
Get-ChildItem -Path "$env:TEMP" -File | Remove-Item -Force -EA SilentlyContinue

# Clearing the Windows Temp folder
Remove-Item -Path 'C:\Windows\Temp\*' -Force -Recurse -EA SilentlyContinue

# Exclude the AME folder while deleting directories in the temporary folder
Get-ChildItem -Path "$env:TEMP" -Directory | Where-Object { $_.Name -ne 'AME' } | Remove-Item -Force -Recurse -EA SilentlyContinue

# As cleanmgr has multiple processes, there's no point in making the window hidden as it won't apply
function Invoke-AtlasDiskCleanup {
	# Kill running cleanmgr instances, as they will prevent new cleanmgr from starting
	Get-Process -Name cleanmgr -ErrorAction SilentlyContinue | Stop-Process -Force -ErrorAction SilentlyContinue
	# Disk Cleanup preset
	# 2 = enabled
	# 0 = disabled
	$baseKey = 'HKLM:\Software\Microsoft\Windows\CurrentVersion\Explorer\VolumeCaches'
	$regValues = @{
		"Active Setup Temp Folders" = 2
		"BranchCache" = 2
		"D3D Shader Cache" = 0
		"Delivery Optimization Files" = 2
		"Diagnostic Data Viewer database files" = 2
		"Downloaded Program Files" = 2
		"Internet Cache Files" = 2
		"Language Pack" = 0
		"Old ChkDsk Files" = 0
		"Recycle Bin" = 0
		"RetailDemo Offline Content" = 2
		"Setup Log Files" = 2
		"System error memory dump files" = 2
		"System error minidump files" = 2
		"Temporary Files" = 0
		"Thumbnail Cache" = 2
		"Update Cleanup" = 2
		"User file versions" = 2
		"Windows Error Reporting Files" = 2
		"Windows Defender" = 2
		"Temporary Sync Files" = 2
		"Device Driver Packages" = 2
	}
	foreach ($entry in $regValues.GetEnumerator()) {
		$key = $entry.Key
		$value = $entry.Value
		$path = "$baseKey\$key"
		Set-ItemProperty -Path $path -Name 'StateFlags0064' -Value $value -Type DWORD
	}
	# Run preset 64 (0-65535)
	Start-Process -FilePath "cleanmgr.exe" -ArgumentList "/sagerun:64"
}

# Check for other installations of Windows
# If so, don't cleanup as it will also cleanup other drives
$excludedDrive = "C"
$drives = Get-PSDrive -PSProvider 'FileSystem' | Where-Object { $_.Name -ne $excludedDrive }
foreach ($drive in $drives) {
    if (Test-Path -Path $(Join-Path -Path $drive.Root -ChildPath 'Windows') -PathType Container) {
        $otherInstalls = $true
    }
}

if (!($otherInstalls)) { Invoke-AtlasDiskCleanup }