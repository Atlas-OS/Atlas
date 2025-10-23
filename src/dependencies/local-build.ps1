param (
	[switch]$AddLiveLog,
	[switch]$ReplaceOldPlaybook,
	[switch]$DontOpenPbLocation,
	[switch]$NoPassword,
	[ValidateSet('Dependencies', 'Requirements', 'WinverRequirement', 'Verification', IgnoreCase = $true)]
	[array]$Removals,
	[string]$FileName = "Atlas Test"
)

$removals | % { Set-Variable -Name "remove$_" -Value $true }

# Convert paths for convenience, needed for Linux/macOS
function Separator {
	return $args -replace '\\', "$([IO.Path]::DirectorySeparatorChar)"
}

# Adds Atlas PSModulesPath to profile for the PowerShell Extension
$userEnv = [System.EnvironmentVariableTarget]::User
if ($psEditor.Workspace.Path -and ([Environment]::GetEnvironmentVariable('LOCALBUILD_DONT_ASK_FOR_MODULES', $userEnv) -ne "$true")) {
	function DontAsk {
		[Environment]::SetEnvironmentVariable('LOCALBUILD_DONT_ASK_FOR_MODULES', $true, $userEnv)
	}

	$title = 'Adding to PowerShell profile'
	$description = @"
Atlas includes some PowerShell modules by default that aren't usually recognised by the VSCode PowerShell extension.
Would you like to add to your PowerShell profile to automatically recognise these modules when developing Atlas?`n`n
"@
	switch ($host.ui.PromptForChoice($title, $description, ('&Yes', '&No', "&Don't ask me again"), 0)) {
		0 {
			if (!(Test-Path $PROFILE)) {
				New-Item -Path $PROFILE -ItemType File -Force | Out-Null
			}

			Add-Content -Path $PROFILE -Value @'
#--LOCAL-BUILD-MODULES-START--#
$workspace = $psEditor.Workspace.Path
$modulesFile = "$workspace\.atlasPsModulesPath"
if ([bool](Test-Path 'Env:\VSCODE_*') -and (Test-Path $workspace -EA 0) -and (Test-Path $modulesFile -EA 0)) {
	$modulePath = Join-Path $workspace (Get-Content $modulesFile -Raw)
	if (!(Test-Path $modulePath -PathType Container)) {
		Write-Warning "Couldn't find module path specified in '$modulesFile', no Atlas modules can be loaded."
	} else {
		$env:PSModulePath += [IO.Path]::PathSeparator + $modulePath
	}
}
#--LOCAL-BUILD-MODULES-END--#
'@

			DontAsk
			& $PROFILE
		}
		2 {
			DontAsk
		}
	}
}

# check 7z
if (Get-Command '7z' -EA 0) {
	$7zPath = '7z'
} elseif (Get-Command '7zz' -EA 0) {
	$7zPath = '7zz'
} elseif (!$IsLinux -and !$IsMacOS -and (Test-Path "$([Environment]::GetFolderPath('ProgramFiles'))\7-Zip\7z.exe")) {
	$7zPath = "$([Environment]::GetFolderPath('ProgramFiles'))\7-Zip\7z.exe"
} else {
	throw "This script requires 7-Zip or NanaZip to be installed to continue."
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
[int]$script:num = 0
function GetNewName {
	while (Test-Path -LiteralPath $apbxFileName) {
		$script:num++
		$script:apbxFileName = "$fileName ($script:num).apbx"
	}
}
if ($replaceOldPlaybook -and (Test-Path -LiteralPath $apbxFileName)) {
	try {
		$stream = [System.IO.File]::Open($(Separator "$PWD\$apbxFileName"), 'Open', 'Read', 'Write')
		$stream.Close()
		Remove-Item -LiteralPath $apbxFileName -Force -EA 0
	} catch {
		Write-Warning "Couldn't replace '$apbxFileName', it's in use."
		GetNewName
	}
} elseif (Test-Path -LiteralPath $apbxFileName) {
	GetNewName
}
$apbxPath = Separator "$PWD\$apbxFileName"

function Invoke-ArchiveCommand {
	param (
		[string[]]$Arguments,
		[string]$Description
	)

	$processOutput = & $7zPath @Arguments 2>&1
	$exitCode = $LASTEXITCODE
	$outputLines = @()
	if ($processOutput) {
		$outputLines = $processOutput | ForEach-Object { [string]$_ }
		$outputLines = $outputLines | ForEach-Object { $_.Trim() } | Where-Object { $_ }
		$outputLines = $outputLines | Where-Object { $_ -ne 'System.Management.Automation.RemoteException' }
	}
	$outputText = $outputLines -join "`n"
	$lockMessagePattern = 'System ERROR: The process cannot access the file because it is being used by another process\.'

	if ($exitCode -gt 1) {
		if ($outputText) {
			throw "$Description failed (7-Zip exit code $exitCode):`n$outputText"
		}
		throw "$Description failed (7-Zip exit code $exitCode)."
	}

	if ($exitCode -eq 1) {
		if ($outputText) {
			Write-Warning "$Description completed with 7-Zip warnings.`n$outputText"
		} else {
			Write-Warning "$Description completed with 7-Zip warnings."
		}
	} elseif ($outputText) {
		if ($outputText -match $lockMessagePattern) {
			Write-Verbose "$Description encountered a transient file lock reported by 7-Zip; continuing with guarded rename."
		} else {
			Write-Verbose "$Description output:`n$outputText"
		}
	}
}

function Move-ItemSafely {
	param (
		[Parameter(Mandatory = $true)][string]$Source,
		[Parameter(Mandatory = $true)][string]$Destination,
		[int]$RetryCount = 5,
		[int]$DelayMilliseconds = 250
	)

	for ($attempt = 1; $attempt -le $RetryCount; $attempt++) {
		try {
			if (Test-Path -LiteralPath $Destination) {
				Remove-Item -LiteralPath $Destination -Force -EA Stop
			}

			Move-Item -LiteralPath $Source -Destination $Destination -Force -EA Stop
			return
		} catch {
			if ($attempt -eq $RetryCount) {
				throw "Failed to finalize playbook archive '$Destination'. $($_.Exception.Message)"
			}

			Start-Sleep -Milliseconds $DelayMilliseconds
		}
	}
}

function Wait-ForFileAccess {
	param (
		[Parameter(Mandatory = $true)][string]$Path,
		[int]$RetryCount = 10,
		[int]$DelayMilliseconds = 200
	)

	for ($attempt = 1; $attempt -le $RetryCount; $attempt++) {
		if (!(Test-Path -LiteralPath $Path -PathType Leaf)) {
			Start-Sleep -Milliseconds $DelayMilliseconds
			continue
		}

		try {
			$stream = [System.IO.File]::Open($Path, [System.IO.FileMode]::Open, [System.IO.FileAccess]::ReadWrite, [System.IO.FileShare]::None)
			$stream.Close()
			return
		} catch {
			if ($attempt -eq $RetryCount) {
				throw "Timed out waiting for exclusive access to '$Path'. $($_.Exception.Message)"
			}

			Start-Sleep -Milliseconds $DelayMilliseconds
		}
	}

	throw "Timed out waiting for '$Path' to be created."
}

# make temp directories
$rootTemp = New-Item (Join-Path -Path $([System.IO.Path]::GetTempPath()) -ChildPath $([System.Guid]::NewGuid())) -ItemType Directory -Force
if (!(Test-Path -Path "$rootTemp")) { throw "Failed to create temporary directory!" }
$playbookTemp = New-Item $(Separator "$rootTemp\playbook") -Type Directory

try {
	# remove entries in playbook config that make it awkward for testing
	$patterns = @()
	# 0.6.5 has a bug where it will crash without the 'Requirements' field, but all of the requirements are removed
	# "<Requirements>" and # "</Requirements>"
	if ($removeRequirements) {$patterns += "<Requirement>"}
	if ($removeWinverRequirement) {$patterns += "<string>", "</SupportedBuilds>", "<SupportedBuilds>"}
	if ($removeVerification) {$patterns += "<ProductCode>"}

	$tempPbConfPath = Separator "$playbookTemp\playbook.conf"
	if ($patterns.Count -gt 0) {
		Get-Content -Encoding "utf8" "playbook.conf" | Where-Object { $_ -notmatch ($patterns -join '|') } | Set-Content -Encoding "utf8" $tempPbConfPath
	}

	$customYmlPath = Separator "Configuration\custom.yml"
	$tempCustomYmlPath = Separator "$playbookTemp\$customYmlPath"
	if ($AddLiveLog) {
		if (Test-Path $customYmlPath -PathType Leaf) {
			New-Item (Split-Path $tempCustomYmlPath -Parent) -ItemType Directory -Force | Out-Null
			Copy-Item -Path $customYmlPath -Destination $tempCustomYmlPath -Force
			$customYml = Get-Content -Path $tempCustomYmlPath

			$liveLogScript = {
$a = Join-Path (Get-ChildItem (Join-Path $([Environment]::GetFolderPath('CommonApplicationData')) '\AME\Logs') -Directory |
Sort-Object LastWriteTime -Descending |
Select-Object -First 1).FullName '\OutputBuffer.txt';
while ($true) { Get-Content -Wait -LiteralPath $a -EA 0 | Write-Output; Start-Sleep 1 }
}
			[string]$liveLogText = ($liveLogScript -replace '"','"""' -replace "'","''").Trim() -replace "`r?`n", " "

			$actionsIndex = $customYml.IndexOf('actions:')
			$newCustomYml = $customYml[0..$actionsIndex] + `
				"  - !cmd: {command: 'start `"AME Wizard Live Log`" PowerShell -NoP -C `"$liveLogText`"'}" + `
				$customYml[($actionsIndex + 1)..($customYml.Count)]

			Set-Content -Path $tempCustomYmlPath -Value $newCustomYml
		} else {
			Write-Error "Can't find '$customYmlPath', not adding live log."
		}
	}

	$startYmlPath = Separator "Configuration\atlas\start.yml"
	$tempStartYmlPath = Separator "$playbookTemp\$startYmlPath"
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
			Write-Error "Can't find '$startYmlPath', not removing dependencies."
		}
	}

	$oemYmlPath = Separator "Configuration\tweaks\misc\config-oem-information.yml"
	$tempOemYmlPath = Separator "$playbookTemp\$oemYmlPath"
	if (Test-Path $oemYmlPath -PathType Leaf) {
		$confXml = ([xml](Get-Content "playbook.conf" -Raw -EA 0)).Playbook
		if ($confXml.Version -match '^(0|[1-9]\d*)(\.(0|[1-9]\d*)){0,2}$') {
			$version = "v$($confXml.Version)"

			if ($confXml.Title | Select-String '(dev)' -Quiet) {
				$version = $version + ' (dev)'
			}

			$oemToReplace = 'AtlasVersionUndefined'
			$oemYml = Get-Content -Path $oemYmlPath -Raw
			$tempOemYml = $oemYml -replace $oemToReplace, $version

			if ($tempOemYml -eq $oemYml) {
				Write-Error "Couldn't find OEM string '$oemToReplace'."
			} else {
				New-Item (Split-Path $tempOemYmlPath) -ItemType Directory -Force | Out-Null
				Set-Content -Path $tempOemYmlPath -Value $tempOemYml
			}
		} else {
			Write-Error "Invalid version format in 'playbook.conf', not setting OEM version."
		}
	} else {
		Write-Error "Can't find '$oemYmlPath', not setting OEM version."
	}

# stage files for packaging
$excludeFiles = @(
	"local-build.*",
	"*.apbx"
)
if (Test-Path $tempCustomYmlPath) { $excludeFiles += "custom.yml" }
if (Test-Path $tempStartYmlPath) { $excludeFiles += "start.yml" }
if (Test-Path $tempPbConfPath) { $excludeFiles += "playbook.conf" }
$stagePath = New-Item (Separator "$rootTemp\stage") -ItemType Directory -Force
$workspaceRoot = (Get-Location).ProviderPath
(Get-ChildItem -File -Exclude $excludeFiles -Recurse) | ForEach-Object {
	$relativePath = $_.FullName.Substring($workspaceRoot.Length + 1)
	$destination = Separator (Join-Path $stagePath $relativePath)
	New-Item (Split-Path $destination -Parent) -ItemType Directory -Force | Out-Null
	Copy-Item -LiteralPath $_.FullName -Destination $destination -Force
}

if (Test-Path $(Separator "$playbookTemp\*")) {
	$playbookTempRoot = (Resolve-Path $playbookTemp).ProviderPath
	Get-ChildItem -LiteralPath $playbookTempRoot -File -Recurse | ForEach-Object {
		$relativeTempPath = $_.FullName.Substring($playbookTempRoot.Length + 1)
		$destination = Separator (Join-Path $stagePath $relativeTempPath)
		New-Item (Split-Path $destination -Parent) -ItemType Directory -Force | Out-Null
		Copy-Item -LiteralPath $_.FullName -Destination $destination -Force
	}
}

if (!$NoPassword) { $pass = '-pmalte' }

$apbxTmpPath = "$apbxPath.tmp"
if (Test-Path -LiteralPath $apbxTmpPath) {
	Remove-Item -LiteralPath $apbxTmpPath -Force -EA 0
}

$createArgs = @('a', '-spf', '-y', '-mx1')
if ($pass) { $createArgs += $pass }
$createArgs += '-tzip'
Push-Location $stagePath
try {
	$createArgs += $apbxPath
	$createArgs += '*'
	Invoke-ArchiveCommand -Arguments $createArgs -Description 'Creating playbook archive'
} finally {
	Pop-Location
}
if (!(Test-Path -LiteralPath $apbxPath -PathType Leaf) -and (Test-Path -LiteralPath $apbxTmpPath -PathType Leaf)) {
	Wait-ForFileAccess -Path $apbxTmpPath
	Move-ItemSafely -Source $apbxTmpPath -Destination $apbxPath
}
Wait-ForFileAccess -Path $apbxPath

if (Test-Path -LiteralPath $apbxTmpPath -PathType Leaf) {
	Wait-ForFileAccess -Path $apbxTmpPath
	Move-ItemSafely -Source $apbxTmpPath -Destination $apbxPath
}

Write-Host "Built successfully! Path: `"$apbxPath`"" -ForegroundColor Green
	if (!$DontOpenPbLocation) {
		if ($IsLinux -or $IsMacOS) {
			Write-Warning "Can't open to APBX directory as the system isn't Windows."
		} else {
			# Kill old instances
			# Would use SetForegroundWindow but it doesn't always work, so opening a new window is most reliable :/
			$openWindows = ((New-Object -Com Shell.Application).Windows() | Where-Object { $_.Document.Folder.Self.Path -eq "$(Split-Path -Path $apbxPath)" })
			if ($openWindows.Count -ne 0) { $openWindows.Quit() }

			explorer /select,"$apbxPath"
		}
	}
} finally {
	Remove-Item $rootTemp -Force -EA 0 -Recurse | Out-Null
	if ($currentDir) { Set-Location $currentDir }
}
