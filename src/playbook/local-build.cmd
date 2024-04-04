<# : batch portion
@echo off & PowerShell -NoP Get-Content """%~f0""" -Raw ^| iex & exit /b
: end batch / begin PowerShell #>

# Do not change anything here, this is simply for reference
$defaultConfig = @{
	# Name of resulting APBX
	fileName = "Atlas Test"

	# Should the script delete any playbook that already exists with the same name or not
	# If not, it will make something like "Atlas Test (1).apbx"
	replaceOldPlaybook = $true

	# Add AME Wizard Live Log window
	liveLog = $true

	# Choose to get Atlas dependencies or not to speed up installation
	removeDependencies = $true

	# Choose not to modify certain aspects from playbook.conf
	removeRequirements = $false
	removeWinverRequirement = $true

	# Not recommended to disable as it will show malicious
	removeProductCode = $true
}

$configPath = "$([Environment]::GetFolderPath('ApplicationData'))\local-build\config.json"

# ------------- #
# config system #
# ------------- #

$shortcut = "$([Environment]::GetFolderPath('LocalApplicationData'))\Microsoft\WindowsApps\ame-lb-conf.lnk"

function New-ConfigPathShortcut {
	$WshShell = New-Object -comObject WScript.Shell
	$Shortcut = $WshShell.CreateShortcut($shortcut)
	$Shortcut.TargetPath = $configPath
	$Shortcut.Save()
}

function CreateConfig($conf) {
	New-Item -Type Directory -Force -Path $(Split-Path $configPath) -ErrorAction SilentlyContinue | Out-Null
	$conf | ConvertTo-Json -Depth 100 | Out-File $configPath
}

function Write-BulletPoint($message) {
	$message | Foreach-Object {
		Write-Host " - " -ForegroundColor Green -NoNewline
		Write-Host $_
	}
	Write-Host ""
}


if (Get-Command '7z.exe' -EA SilentlyContinue) {
	$7zPath = '7z.exe'
} elseif (Test-Path "$([Environment]::GetFolderPath('ProgramFiles'))\7-Zip\7z.exe") {
	$7zPath = "$([Environment]::GetFolderPath('ProgramFiles'))\7-Zip\7z.exe"
}
if (!$7zPath) {
	Write-Host "This script requires 7-Zip to be installed to continue."
	Pause
	exit 1
}

if (!(Test-Path $configPath)) {
	Remove-Item -Force -Path $shortcut -EA SilentlyContinue

	Write-Host "It seems like this is your first time using AME Local Build.`n" -ForegroundColor Cyan

	Write-BulletPoint "Adding config to %PATH% would allow you to type 'ame-lb-conf' into Run or any other shell and open the config."
	Write-BulletPoint "The configuration is in JSON, and explanations of those arguments are contained in the script."
	Write-BulletPoint "You can change the config path by modifying the script."


	Write-Host "`n---------------------------------------------------------------------------------------------------------`n" -ForegroundColor Magenta
	choice /c:yn /n /m "Would you like to add a shortcut to %PATH% for the configuration file? [Y/N]"
	if ($LASTEXITCODE -eq 1) { New-ConfigPathShortcut }

	choice /c:yn /n /m "Would you like to open the config file now? [Y/N]"
	CreateConfig $defaultConfig
	if ($LASTEXITCODE -eq 1) {
		Start-Process -FilePath "notepad.exe" -ArgumentList $configPath -Wait
	}
	Write-Host ""

	3..1 | ForEach-Object {
		Write-Host "`rCompleted, building playbook in $_... " -NoNewLine -ForegroundColor Yellow
		Start-Sleep 1
	}
}

# check if path shortcut matches config path
if (Test-Path $shortcut) {
	if ($configPath -ne $(New-Object -ComObject WScript.Shell).CreateShortcut($shortcut).TargetPath) { New-ConfigPathShortcut }
}

try {
	$configNotHashtable = Get-Content $configPath | ConvertFrom-Json
	# convert JSON config to hashtable
	$config = @{}; foreach ($property in $configNotHashtable.PSObject.Properties) { $config[$property.Name] = $property.Value }
} catch {
	Write-Host "Your configuration is corrupted." -ForegroundColor Yellow
	choice /c:yn /n /m "Would you like to reset it? [Y/N]"
	if ($LASTEXITCODE -eq 1) {
		CreateConfig $defaultConfig
	} else {exit 1}
}

# update config
$defaultConfig.Keys | ForEach-Object {
	if ($config.Keys -notcontains $_) {
		$config = $config + @{
			$_ = $defaultConfig.$_
		}
		$updateConfig = $true
	}
}
if ($updateConfig) {CreateConfig $config}

foreach ($a in $config.Keys) {
	New-Variable -Name $a -Value $config.$a
}

# ----------- #
# main script #
# ----------- #

$apbxFileName = "$fileName.apbx"
$apbxPath = "$PWD\$fileName.apbx"

if (!(Test-Path -Path "playbook.conf")) {
	Write-Host "playbook.conf file not found in the current directory." -ForegroundColor Red
	Start-Sleep 2
	exit 1
}

# check if old files are in use
$num = 1
if (($replaceOldPlaybook) -and (Test-Path -Path $apbxFileName)) {
	try {
		$stream = [System.IO.File]::Open($apbxFileName, 'Open', 'Read', 'Write')
		$stream.Close()
	} catch {
		while(Test-Path -Path "$fileName ($num).apbx") {$num++}
		$apbxFileName = "$PWD\$fileName ($num).apbx"
	}
	Remove-Item -Path $apbxFileName -Force -EA 0
} else {
	if (Test-Path -Path $apbxFileName) {
		while(Test-Path -Path "$fileName ($num).apbx") {$num++}
		$apbxFileName = "$PWD\$fileName ($num).apbx"
	}
}

$zipFileName = Join-Path -Path $PWD -ChildPath $([System.IO.Path]::ChangeExtension($apbxFileName, "zip"))

# remove old temp files
Remove-Item -Path $zipFileName -Force -EA 0
if (!($?) -and (Test-Path -Path "$zipFileName")) {
	Write-Host "Failed to delete temporary '$zipFileName' file!" -ForegroundColor Red
	Start-Sleep 2
	exit 1
}

# make temp directories
$rootTemp = Join-Path -Path $env:TEMP -ChildPath $([System.IO.Path]::GetRandomFileName())
New-Item $rootTemp -ItemType Directory -Force | Out-Null
if (!(Test-Path -Path "$rootTemp")) {
	Write-Host "Failed to create temporary directory!" -ForegroundColor Red
	Start-Sleep 2
	exit 1
}
$configDir = "$rootTemp\playbook\Configuration\atlas"
New-Item $configDir -ItemType Directory -Force | Out-Null

try {
	$tempPlaybookConf = "$rootTemp\playbook\playbook.conf"
	$ymlPath = "Configuration\custom.yml"
	$tempStartYML = "$rootTemp\playbook\$ymlPath"

	# remove entries in playbook config that make it awkward for testing
	$patterns = @()
	# 0.6.5 has a bug where it will crash without the 'Requirements' field, but all of the requirements are removed
	# "<Requirements>" and # "</Requirements>"
	if ($removeRequirements) {$patterns += "<Requirement>"}
	if ($removeWinverRequirement) {$patterns += "<string>", "</SupportedBuilds>", "<SupportedBuilds>"}
	if ($removeProductCode) {$patterns += "<ProductCode>"}

	if ($patterns.Count -gt 0) {
		$newContent = Get-Content "playbook.conf"| Where-Object { $_ -notmatch ($patterns -join '|') }
		$newContent | Set-Content "$tempPlaybookConf" -Force	
	}

	if ($removeDependencies -or $liveLog) {
		$startYML = "$PWD\$ymlPath"
		if (Test-Path $startYML -PathType Leaf) {
			Copy-Item -Path $startYML -Destination $tempStartYML -Force

			$content = Get-Content -Path $tempStartYML

			if ($liveLog) {
				# uncomment the 8th line (6 in PowerShell because arrays are zero-based)
				if ($content.Count -gt 6) {
					$content[6] = $content[6] -replace ' #', ''
				}
			}

			if ($removeDependencies) {
				# has to be raw for removing dependencies
				$content = $content -join "`n"

				$startMarker = "  ################ NO LOCAL BUILD ################"
				$endMarker = "  ################ END NO LOCAL BUILD ################"

				$startIndex = $content.IndexOf($startMarker)
				$endIndex = $content.IndexOf($endMarker)

				if ($startIndex -ge 0 -and $endIndex -ge 0) {
					$content = $content.Substring(0, $startIndex) + $content.Substring($endIndex + $endMarker.Length)
				}
			}

			Set-Content -Path $tempStartYML -Value $content
		}
	}

	$excludeFiles = @(
		"local-build.cmd",
		"*.apbx"
	)
	if (Test-Path $tempStartYML) { $excludeFiles += "custom.yml" }
	if (Test-Path $tempPlaybookConf) { $excludeFiles += "playbook.conf" }

	# make playbook, 7z is faster
	if (Test-Path $apbxPath) { Remove-Item $apbxFileName -Force }

	(Get-ChildItem -File -Exclude $excludeFiles -Recurse).FullName `
	| Resolve-Path -Relative | ForEach-Object {$_.Substring(2)} | Out-File "$rootTemp\7zFiles.txt" -Encoding utf8

	& $7zPath a -spf -y -mx1 -tzip "$apbxPath" `@"$rootTemp\7zFiles.txt" | Out-Null
	# add edited files
	Push-Location "$rootTemp\playbook"
	& $7zPath u "$apbxPath" * | Out-Null
	Pop-Location

	Write-Host "Build successfully! Path: `"$apbxPath`"" -ForegroundColor Green
	Start-Sleep 1
} finally {
	Remove-Item $rootTemp -Force -EA 0 -Recurse | Out-Null
}