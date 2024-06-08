param (
	[switch]$AddLiveLog,
	[switch]$ReplaceOldPlaybook,
	[switch]$DontOpenPbLocation,
	[ValidateSet('Dependencies', 'Requirements', 'WinverRequirement', 'Verification', IgnoreCase = $true)]
	[array]$Removals,
	[string]$FileName = "Atlas Test"
)

$removals | % { Set-Variable -Name "remove$_" -Value $true }

# check 7z
if (Get-Command '7z' -EA 0) {
	$7zPath = '7z'
} elseif (Get-Command '7zz' -EA 0) {
	$7zPath = '7zz'
} elseif (!$IsLinux -and !$IsMacOS -and (Test-Path "$([Environment]::GetFolderPath('ProgramFiles'))\7-Zip\7z.exe")) {
	$7zPath = "$([Environment]::GetFolderPath('ProgramFiles'))\7-Zip\7z.exe"
} else {
	throw "This script requires 7-Zip to be installed to continue."
}

# check if playbook dir
if (!(Test-Path playbook.conf -PathType Leaf)) {
	if (Test-Path playbook -PathType Container) {
		$currentDir = $PWD
		Set-Location playbook
		if (!(Test-Path playbook.conf -PathType Leaf)) { throw "playbook.conf file not found in playbook directory." }
	} else {
		throw "playbook.conf file not found in the current directory."
	}
}

# check if old files are in use
$apbxFileName = "$fileName.apbx"
function GetNewName {
	while (Test-Path -Path $apbxFileName) {
		$num++
		$script:apbxFileName = "$fileName ($num).abpx"
	}
}
if ($replaceOldPlaybook -and (Test-Path -Path $apbxFileName)) {
	try {
		$stream = [System.IO.File]::Open("$PWD\$apbxFileName", 'Open', 'Read', 'Write')
		$stream.Close()
		Remove-Item -Path $apbxFileName -Force -EA 0
	} catch {
		Write-Warning "Couldn't replace '$apbxFileName', it's in use."
		GetNewName
	}
} elseif (Test-Path -Path $apbxFileName) {
	GetNewName
}
$apbxPath = "$PWD\$apbxFileName"

# make temp directories
$rootTemp = New-Item (Join-Path -Path $([System.IO.Path]::GetTempPath()) -ChildPath $([System.Guid]::NewGuid())) -ItemType Directory -Force
if (!(Test-Path -Path "$rootTemp")) { throw "Failed to create temporary directory!" }
$playbookTemp = New-Item "$rootTemp\playbook" -Type Directory

try {
	# remove entries in playbook config that make it awkward for testing
	$patterns = @()
	# 0.6.5 has a bug where it will crash without the 'Requirements' field, but all of the requirements are removed
	# "<Requirements>" and # "</Requirements>"
	if ($removeRequirements) {$patterns += "<Requirement>"}
	if ($removeWinverRequirement) {$patterns += "<string>", "</SupportedBuilds>", "<SupportedBuilds>"}
	if ($removeVerification) {$patterns += "<ProductCode>"}

	$tempPbConfPath = "$playbookTemp\playbook.conf"
	if ($patterns.Count -gt 0) {
		Get-Content "playbook.conf" | Where-Object { $_ -notmatch ($patterns -join '|') } | Set-Content $tempPbConfPath
	}

	$customYmlPath = "Configuration\custom.yml"
	$tempCustomYmlPath = "$playbookTemp\$customYmlPath"
	if ($AddLiveLog) {
		if (Test-Path $customYmlPath -PathType Leaf) {
			New-Item (Split-Path $tempCustomYmlPath -Parent) -ItemType Directory -Force | Out-Null
			Copy-Item -Path $customYmlPath -Destination $tempCustomYmlPath -Force
			$customYml = Get-Content -Path $tempCustomYmlPath

			$actionsIndex = $customYml.IndexOf('actions:')
			$newCustomYml = $customYml[0..$actionsIndex] + `
				"  - !powerShell: {command: 'gc -Wait Logs\TIOutput.txt -EA 0 | Write-Output; pause', baseDir: true, wait: false}" + `
				$customYml[($actionsIndex + 1)..($customYml.Count)]

			Set-Content -Path $tempCustomYmlPath -Value $newCustomYml
		} else {
			Write-Error "Can't find "$customYmlPath", not adding live log."
		}
	}

	$startYmlPath = "Configuration\atlas\start.yml"
	$tempStartYmlPath = "$playbookTemp\$startYmlPath"
	if ($removeDependencies) {
		if (Test-Path $startYmlPath -PathType Leaf) {
			New-Item (Split-Path $tempStartYmlPath -Parent) -ItemType Directory -Force | Out-Null
			Copy-Item -Path $startYmlPath -Destination $tempStartYmlPath -Force
			$startYml = Get-Content -Path $tempStartYmlPath

			$noLocalBuildStart = $startYml.IndexOf('  ################ NO LOCAL BUILD ################')
			$noLocalBuildEnd = $startYml.IndexOf('  ################ END NO LOCAL BUILD ################')
			$newStartYml = $startYml[0..($noLocalBuildStart - 1)] + `
				$startYml[($noLocalBuildEnd + 1)..($startYml.Count)]

			Set-Content -Path $tempStartYmlPath -Value $newStartYml
		} else {
			Write-Error "Can't find "$startYmlPath", not removing dependencies."
		}
	}

	# exclude files
	$excludeFiles = @(
		"local-build.cmd",
		"*.apbx"
	)
	if (Test-Path $tempCustomYmlPath) { $excludeFiles += "custom.yml" }
	if (Test-Path $tempStartYmlPath) { $excludeFiles += "start.yml" }
	if (Test-Path $tempPbConfPath) { $excludeFiles += "playbook.conf" }
	$files = "$rootTemp\7zFiles.txt"
	(Get-ChildItem -File -Exclude $excludeFiles -Recurse).FullName | Resolve-Path -Relative | ForEach-Object {$_.Substring(2)} | Out-File $files -Encoding utf8

	& $7zPath a -spf -y -mx1 -tzip "$apbxPath" `@"$files" | Out-Null
	# add edited files
	if (Test-Path "$playbookTemp\*.*") {
		Push-Location "$playbookTemp"
		& $7zPath u "$apbxPath" * | Out-Null
		Pop-Location
	}

	Write-Host "Built successfully! Path: `"$apbxPath`"" -ForegroundColor Green
	if (!$IsLinux -and !$IsMacOS -and !$DontOpenPbLocation) {
		explorer /select,"$apbxPath"
	}
} finally {
	Remove-Item $rootTemp -Force -EA 0 -Recurse | Out-Null
	if ($currentDir) { Set-Location $currentDir }
}