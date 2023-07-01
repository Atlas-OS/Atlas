<# : batch portion
@echo off & powershell -nop Get-Content "%~f0" -Raw ^| iex & exit /b
: end batch / begin PowerShell #>

# name of resulting apbx
$fileName = "Atlas Test"

# if the script should delete any playbook that already exists with the same name or not
# if not, it will make something like "Atlas Test (1).apbx"
$replaceOldPlaybook = $true

# choose not to modify certain aspects from playbook.conf
$removeRequirements = $true
$removeBuildRequirement = $true
# not recommended to disable as it will show malicious
$removeProductCode = $true

# ------ #
# script #
# ------ #

$excludeFiles = @("local-build.cmd", "Release ZIP", "playbook.conf")
$apbxFileName = "$fileName.apbx"
# playbook that is modified for removing requirements
$tempPlaybook = "$env:temp\playbook.conf"

if (!(Test-Path -Path "playbook.conf")) {
	Write-Host "playbook.conf file not found in the current directory." -ForegroundColor Red
	Start-Sleep 2
	exit 1
}

# check if old files are in use
if (($replaceOldPlaybook) -and (Test-Path -Path $apbxFileName)) {
	try {
		$stream = [System.IO.File]::Open($apbxFileName, 'Open', 'Read', 'Write')
		$stream.Close()
	} catch {
		Write-Host "The current playbook in the folder ($apbxFileName) is in use, and it can't be deleted to be replaced." -ForegroundColor Red
		Write-Host 'Either configure "$replaceOldPlaybook" in the script configuration or close the application its in use with.' -ForegroundColor Red
		Start-Sleep 4
		exit 1
	}
	Remove-Item -Path $apbxFileName -Force -EA 0
} else {
	if (Test-Path -Path $apbxFileName) {
		$num = 1
		while(Test-Path -Path "$fileName ($num).apbx") {$num++}
		$apbxFileName = "$fileName ($num).apbx"
	}
}

$zipFileName = [System.IO.Path]::ChangeExtension($apbxFileName, "zip")

# remove old temp files
Remove-Item -Path $zipFileName -Force -EA 0
if (!($?) -and (Test-Path -Path "$zipFileName")) {
	Write-Host "Failed to delete temporary '$zipFileName' file!" -ForegroundColor Red
	Start-Sleep 2
	exit 1
}
Remove-Item -Path "playbook.conf.old" -Force -EA 0
if (!($?) -and (Test-Path -Path "playbook.conf.old")) {
	Write-Host "Failed to delete temporary 'playbook.conf.old' file!" -ForegroundColor Red
	Start-Sleep 2
	exit 1
}

$filteredItems = (Get-ChildItem | Where-Object { $excludeFiles -notcontains $_.Name -and $_.Name -notlike "*.apbx" }).FullName + "$tempPlaybook"

# remove entries in playbook config that make it awkward for testing
$patterns = @()
if ($removeRequirements) {$patterns += "<Requirement>"}
# 0.6.5 has a bug where it will crash without the 'Requirements' field
# Fixed next release
# "<Requirements>"
# "</Requirements>"
if ($removeBuildRequirement) {$patterns += "<string>", "</SupportedBuilds>", "<SupportedBuilds>"}
if ($removeProductCode) {$patterns += "<ProductCode>"}

$newContent = Get-Content "playbook.conf" | Where-Object { $_ -notmatch ($patterns -join '|') }
$newContent | Set-Content "$tempPlaybook" -Force

# make playbook
Compress-Archive -Path $filteredItems -DestinationPath $zipFileName
Rename-Item -Path $zipFileName -NewName $apbxFileName

Write-Host "Completed." -ForegroundColor Green