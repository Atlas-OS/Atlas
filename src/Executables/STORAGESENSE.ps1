# Reference: https://gist.github.com/he3als/3d9dcf6e796aa920c24a98130165fb17
$properties = @{
	# Enable Storage Sense
 	"01" = 1
	# Run Storage Sense
	"1024" = 1
	# Run Storage Sense every month
	"2048" = 30
	# Enable cleaning temp files
	"04" = 1
	# Disable downloads being cleared
	"32" = 0
	# Disable OneDrive cleanup
	"02" = 0
	"128" = 0
	# Clean recycle bin every month
	"08" = 1
	"256" = 30
}

$Path = "HKCU:\Software\Microsoft\Windows\CurrentVersion\StorageSense\Parameters\StoragePolicy"

$properties.GetEnumerator() | ForEach-Object {
	Set-ItemProperty -Path $Path -Name $_.Key -Type DWORD -Value $_.Value -Force
}

# Enable cleaning temp files
Enable-ScheduledTask -TaskName "Microsoft\Windows\DiskCleanup\SilentCleanup"

# Disable OneDrive cleanup for subkeys
Get-ChildItem -Path "$Path\OneDrive*" |
	ForEach-Object {
		Set-ItemProperty -Path $_.PSPath -Name "02" -Type DWORD -Value 0 -Force
		Set-ItemProperty -Path $_.PSPath -Name "128" -Type DWORD -Value 0 -Force
	}
