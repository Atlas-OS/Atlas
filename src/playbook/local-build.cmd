<# : batch portion
@echo off & powershell -nop Get-Content """%~f0""" -Raw ^| iex & exit /b
: end batch / begin PowerShell #>

# name of resulting apbx
$fileName = "Atlas Test"

# if the script should delete any playbook that already exists with the same name or not
# if not, it will make something like "Atlas Test (1).apbx"
$replaceOldPlaybook = $true

# choose to get Atlas dependencies or not to speed up installation
$removeDependencies = $false
# choose not to modify certain aspects from playbook.conf
$removeRequirements = $false
$removeBuildRequirement = $true
# not recommended to disable as it will show malicious
$removeProductCode = $true

# ------ #
# script #
# ------ #

$excludeFiles = @("local-build.cmd", "playbook.conf")
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

$filteredItems = @()
$filteredItems = $filteredItems + (Get-ChildItem | Where-Object { $excludeFiles -notcontains $_.Name -and $_.Name -notlike "*.apbx" }).FullName + "$tempPlaybook"

# remove entries in playbook config that make it awkward for testing
$patterns = @()
# 0.6.5 has a bug where it will crash without the 'Requirements' field, but all of the requirements are removed
# "<Requirements>" and # "</Requirements>"
if ($removeRequirements) {$patterns += "<Requirement>"}
if ($removeBuildRequirement) {$patterns += "<string>", "</SupportedBuilds>", "<SupportedBuilds>"}
if ($removeProductCode) {$patterns += "<ProductCode>"}

$newContent = Get-Content "playbook.conf" | Where-Object { $_ -notmatch ($patterns -join '|') }
$newContent | Set-Content "$tempPlaybook" -Force

if ($removeDependencies) {
	$startYML = "$PWD\Configuration\atlas\start.yml"
	$tempPath = "$env:TEMP\start.yml"
	if (Test-Path $startYML -PathType Leaf) {
		Copy-Item -Path $startYML -Destination $tempPath -Force

		$content = Get-Content -Path $tempPath -Raw

		$startMarker = "  ################ NO LOCAL BUILD ################"
		$endMarker = "  ################ END NO LOCAL BUILD ################"

		$startIndex = $content.IndexOf($startMarker)
		$endIndex = $content.IndexOf($endMarker)

		if ($startIndex -ge 0 -and $endIndex -ge 0) {
			$newContent = $content.Substring(0, $startIndex) + $content.Substring($endIndex + $endMarker.Length)
			Set-Content -Path $startYML -Value $newContent
		}
	}
}

# make playbook
Compress-Archive -Path $filteredItems -DestinationPath $zipFileName
Rename-Item -Path $zipFileName -NewName $apbxFileName

# add back unmodified start.yml
Copy-Item -Path $tempPath -Destination $startYML -Force

Write-Host "Completed." -ForegroundColor Green
Start-Sleep 1